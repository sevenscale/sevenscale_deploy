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
    desc 'Create all users'
    task :default do
      tasks.each do |name, task|
        execute_task(task) unless task == default_task
      end
    end
  end

  def activate(user, options = {})
    namespace :create do
      desc "Create user #{user}#{' with all user keys' if options[:all_keys]}"
      task user do
        create_user(user, options)
      end
    end
  end

  def create_user(user, options = {})
    via = fetch(:user) == 'root' ? :run : :sudo

    command = "grep -q '^#{user}:' /etc/passwd || /usr/sbin/useradd #{user}"
    command_options = ''

    if options[:groups]
      command_options << " -G #{Array(options[:groups]).join(',')}"
    end

    if options[:password]
      command_options << %{ --password '#{options[:password]}'}
    end

    invoke_command %{/bin/sh -c "#{command}"}, :via => via

    unless command_options.empty?
      invoke_command %{/usr/sbin/usermod #{command_options} #{user}}, :via => via
    end

    update_authorized_keys2(user, options[:all_keys])
  end

  def update_authorized_keys2(user, all_keys = false)
    via = fetch(:user) == 'root' ? :run : :sudo

    key_files = all_keys ? Dir["ssh_keys/*/*"] : Dir["ssh_keys/#{user}/*"]
    user_keys = key_files.collect { |file| [ "# #{file}:"] + File.read(file).split(/(\r?\n)+/) }.flatten

    authorized_keys_file = "/tmp/#{user}-authorized_keys2.#{$$}"

    put user_keys.join("\n"), authorized_keys_file, :mode => 0600

    commands = "/usr/bin/install -D -b -m 0600 -o #{user} -g #{user} #{authorized_keys_file} ~#{user}/.ssh/authorized_keys2"
    commands << " && chown -R #{user}.#{user} ~#{user}/.ssh"
    commands << " && chmod 0700 ~#{user}/.ssh; rm -f #{authorized_keys_file}"

    invoke_command %{/bin/sh -c "#{commands}"}, :via => via
  end

  def connect_as_root
    normal_user = fetch(:user)
    normal_password = fetch(:password)

    logger.info "Command must run as root. Please specify root password."
    set(:user, 'root')
    set(:password, Capistrano::CLI.password_prompt)

    yield
  ensure
    set(:user, normal_user)
    set(:password, normal_password)
  end
end
