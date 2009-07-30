# Capistrano plugin to manage sudoers
#
# Author: Eric Lindvall <eric@sevenscale.com>
#
#
# Usage:
#
# # Enable the user set for the application
# sudoers_manager.enable fetch(:user)
#
# # Enable the wheel group
# sudoers_manager.enable_wheel
# 
module SudoersManager
  @@users = []

  def users
    @@users
  end

  def enable_wheel
    namespace :sudoers do
      namespace :apply do
        desc "Enable users in the wheel group"
        task :wheel do
          sudoers_manager.run_as_root do
            sudoers_manager.apply_to_sudoers [
              "%wheel	ALL=(ALL)	ALL"
            ]
          end
        end
      end
    end
  end

  def enable(target_user)
    @@users << target_user

    namespace :sudoers do
      namespace :apply do
        desc "Apply all sudoers"
        task :default do
          sudoers_manager.run_as_root do
            sudoers_manager.users.each do |user|
              send(user)
            end

            if respond_to?(:wheel)
              send(:wheel)
            end
          end
        end

        desc "Apply sudoers for #{target_user}"
        task target_user do
          sudoers_manager.run_as_root do
            sudoers_manager.apply_to_sudoers [
              "Defaults:#{target_user} !requiretty",
              "#{target_user} ALL=(ALL)       NOPASSWD: ALL"
            ]
          end
        end
      end
    end
  end

  def apply_to_sudoers(lines)
    lines = Array(lines)

    run %{test '!' -f /etc/sudoers.tmp && touch /etc/sudoers.tmp}

    sudoers = ''
    run("cat /etc/sudoers") { |channel, stream, data| sudoers << data if stream == :out }

    sudoers_lines = sudoers.split(/\r?\n/)
    sudoers_lines += [ "", lines.select { |line| sudoers_lines.include?(line) }, "" ]
      
    put sudoers_lines.flatten.join("\n"), '/etc/.cap.sudoers', :mode => 0600

    run %{visudo -c -f /etc/.cap.sudoers && cp /etc/sudoers /etc/sudoers~ && mv /etc/.cap.sudoers /etc/sudoers && rm -f /etc/sudoers.tmp }
  rescue
    run "rm -f /etc/sudoers.tmp"
    raise
  end
  
  def run_as_root
    begin
      normal_user = fetch(:user)

      if normal_user != 'root'
        normal_password = fetch(:password)

        if fetch(:root_needs_password, true)
          logger.info "Command must run as root. Please specify root password."
          set(:user, 'root')
          set(:password, Capistrano::CLI.password_prompt)
        end
      end
    
      yield
    ensure
      if normal_user != 'root'
        set(:user, normal_user)
        set(:password, normal_password)
      end
    end
  end
end

Capistrano.plugin :sudoers_manager, SudoersManager
