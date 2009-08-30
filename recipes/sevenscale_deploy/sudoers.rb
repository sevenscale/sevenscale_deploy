# Capistrano plugin to manage sudoers
#
# Author: Eric Lindvall <eric@sevenscale.com>
#
#
# Usage:
#
# # Enable the user set for the application
# sudoers.enable fetch(:user)
#
# # Enable the wheel group
# sudoers.enable_wheel
#
Capistrano::Configuration.instance(:must_exist).load do
  namespace :sudoers do
    namespace :apply do
      desc "Apply all sudoers"
      task :default do
        tasks.each do |name, task|
          execute_task(task) unless task == default_task
        end
      end
    end


    def enable_wheel(options = {})
      namespace :apply do
        desc "Enable users in the wheel group"
        task :wheel do
          if options[:no_password]
            sudoers.apply_to_sudoers [ "%wheel	ALL=(ALL)	NOPASSWD: ALL" ]
          else
            sudoers.apply_to_sudoers [ "%wheel	ALL=(ALL)	ALL" ]
          end
        end
      end
    end

    def enable(target_user)
      namespace :apply do
        desc "Apply sudoers for #{target_user}"
        task target_user do
          sudoers.apply_to_sudoers [
            "Defaults:#{target_user} !requiretty",
            "#{target_user} ALL=(ALL)       NOPASSWD: ALL"
          ]
        end
      end
    end

    def apply_to_sudoers(lines)
      via   = fetch(:user) == 'root' ? :run : :sudo
      lines = Array(lines)

      # Lock sudoers file to prevent visudo from working
      invoke_command %{/bin/sh -c "test '!' -f /etc/sudoers.tmp && touch /etc/sudoers.tmp"}, :via => via

      sudoers = capture("cat /etc/sudoers", :via => via).split(/\r?\n/)
      sudoers += [ "", lines.reject { |line| sudoers.include?(line) }, "" ]

      sudoers_temporary = "/tmp/.cap.sudoers.#{$$}"

      put sudoers.flatten.join("\n"), sudoers_temporary, :mode => 0440

      commands = []
      commands << "/usr/sbin/visudo -c -f #{sudoers_temporary}"
      commands << "/usr/bin/install -b -m 440 -o root -g root #{sudoers_temporary} /etc/sudoers"
      commands << "rm -f #{sudoers_temporary} /etc/sudoers.tmp"

      invoke_command %{/bin/sh -c "#{commands.join(' && ')}"}, :via => via
    rescue
      # Remove sudoers lock file
      invoke_command "rm -f #{sudoers_temporary} /etc/sudoers.tmp", :via => via
      raise
    end
  end
end