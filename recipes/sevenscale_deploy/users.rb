# Capistrano plugin to manage users
#
# Author: Eric Lindvall <eric@sevenscale.com>
#
# Usage:
#
# # Enable the user set for the application
# users.activate fetch(:user), :all_keys => true
# users.activate 'eric',       :groups => 'wheel', :password => '$1$iavkeX$qLiAcv5ga5TkmfYJx/'
#
#
# Key Location:
#
# Store the keys in ssh_keys/<user>/key_file_name
#
# You can name the file anything you want -- the hostname of the system
# is safe.
#

namespace :users do
  namespace :create do
    def users_to_activate
      @users_to_activate ||= []
    end

    desc 'Create all users'
    task :default do
      users_to_activate.each do |name|
        execute_task(tasks[name.to_sym])
      end
    end
  end

  def activate(user, options = {})
    namespace :create do
      users_to_activate << user

      desc "Create user #{user}#{' with all user keys' if options[:all_keys]}"
      task user do
        create_user(user, options)
      end
    end
  end

  def create_user(user, options = {})
    via = fetch(:user) == 'root' ? :run : :sudo

    command = "grep -q '^#{user}:' /etc/passwd || /usr/sbin/useradd #{user}"

    if options[:uid]
      command << " -u #{options[:uid]}"
    end
    
    if options[:options]
      command << " #{options[:options]}"
    end

    invoke_command %{/bin/sh -c "#{command}"}, :via => via

    usermod_options = ''

    if options[:groups]
      usermod_options << " -G #{Array(options[:groups]).join(',')}"
    end

    if options[:password]
      usermod_options << %{ --password '#{options[:password]}'}
    end

    if options[:uid]
      usermod_options << %{ -u #{options[:uid]}}
    end
    

    unless usermod_options.empty?
      invoke_command %{/usr/sbin/usermod #{usermod_options} #{user}}, :via => via
    end

    update_authorized_keys2(user, options[:all_keys])
  end

  def update_authorized_keys2(user, all_keys = false)
    via = fetch(:user) == 'root' ? :run : :sudo

    key_files = all_keys ? Dir["ssh_keys/*/*"] : Dir["ssh_keys/#{user}/*"]
    user_keys = key_files.collect { |file| [ "# #{file}:"] + File.read(file).split(/(\r?\n)+/) }.flatten

    unless user_keys.empty?
      authorized_keys_file = "/tmp/#{user}-authorized_keys2.#{$$}"

      put user_keys.join("\n"), authorized_keys_file, :mode => 0600

      commands = "/usr/bin/install -D -b -m 0600 -o #{user} -g #{user} #{authorized_keys_file} ~#{user}/.ssh/authorized_keys2"
      commands << " && chown -R #{user}.#{user} ~#{user}/.ssh"
      commands << " && chmod 0700 ~#{user}/.ssh; rm -f #{authorized_keys_file}"

      invoke_command %{/bin/sh -c "#{commands}"}, :via => via
    end
  end

  def brute_force_authenticate
    auths           = [ [ fetch(:user), fetch(:password) ] ]
    auths_by_server = Hash.new{ |h,k| h[k] = [] }

    find_servers.each do |server|
      server_authed = auths.any? do |u, p|
        if can_authenticate?(server, u, p)
          auths_by_server[[u,p]] << server
        end
      end

      if not server_authed
        loop do
          u = Capistrano::CLI.ui.ask("#{server.host} username: ")
          p = nil
          if can_authenticate?(server, u, p)
            auths                  << [ u, p ]
            auths_by_server[[u,p]] << server
            break
          else
            p = Capistrano::CLI.password_prompt("#{server.host} password: ")
            if can_authenticate?(server, u, p)
              auths                  << [ u, p ]
              auths_by_server[[u,p]] << server
              break
            end
          end
        end
      end
    end

    auths_by_server
  end

  def connect_as(user, password, &block)
    old_user, old_password = fetch(:user), fetch(:password)

    if user != old_user
      changed_user = true
      set(:user, user)
      set(:password, password)

      logger.info "Running following commands as '#{user}'"
      teardown_connections_to(sessions.keys)
    end

    return block.call
  ensure
    if changed_user
      set(:user, old_user)
      set(:password, old_password)

      logger.info "Switching back to '#{old_user}'"
      teardown_connections_to(sessions.keys)
    end
  end

  desc "Ensure all systems can fully authenticate"
  task :authenticate do
    brute_force_authenticate.each do |(user, password), servers|
      users.connect_as(user, password) do
        hosts = servers.map { |s| s.host }

        with_env('HOSTFILTER', hosts.join(',')) do
          users.create.default
          sudoers.apply.default
        end
      end
    end
  end

  def can_authenticate?(server, user, password)
    via = user == 'root' ? :run : :sudo
    users.connect_as(user, password) do
      begin
        invoke_command('/usr/bin/id', :via => via, :hosts => server)
        return true
      rescue Capistrano::ConnectionError, Capistrano::CommandError
        return false
      end
    end
  end

  def connect_as_root(&block)
    logger.info "Command must run as root. Please specify root password."
    users.connect_as('root', Capistrano::CLI.password_prompt, &block)
  end
end
