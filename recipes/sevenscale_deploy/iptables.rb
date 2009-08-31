# Capistrano plugin to manage iptables
#
# Author: Eric Lindvall <eric@sevenscale.com>
#
# Usage:
#
# # Allow web and SSL for app servers
# iptables.role :app, 80, 443
#
# # Allow ActiveMQ Stomp connections from app instances
# iptables.role :activemq, 61613, :from_roles => %w(app)
#
# # Allow mysql from any app server
# iptables.role :db, 3306, :from_roles => %w(app)
#
Capistrano::Configuration.instance(:must_exist).load do
  namespace :iptables do
    def rules
      @@rules ||= Hash.new { |h,role| h[role] = [] }
    end

    namespace :apply do
      desc "Apply all iptables settings"
      task :default do
        tasks.each do |name, task|
          execute_task(task) unless task == default_task
        end
      end
    end

    def all(port, options = {})
      role(:all, port, options)
    end

    def role(role, *ports)
      options = ports.extract_options!
      task_opts = role == :all ? {} : { :roles => role }

      options[:protocol] ||= 'tcp'

      ports.each do |port|
        iptables.rules[role.to_sym] << options.merge({ :port => port })

        port_description = iptables.rules[role.to_sym].map { |o| "#{o[:port]}/#{o[:protocol]}" }.join(', ')

        namespace :apply do
          desc "Allow port #{port_description} in iptables"
          task role, task_opts do
            chain_prefix = "#{fetch(:application).upcase}-#{role.to_s.upcase}"
            chain = "#{chain_prefix[0..23]}-INPUT"

            commands = iptables.flush_commands(chain)

            commands += iptables.rules[role.to_sym].collect do |rule|
              iptables.enable_commands(chain, rule[:port], rule[:protocol], rule)
            end

            sudo %{/bin/sh -c "#{commands.flatten.join(' && ')}"}

            iptables.save
          end
        end
      end
    end

    def enable(chain, port, protocol, options = {})
      sudo iptables.enable_commands(chain, port, protocol, options).join(' && ')
    end

    def flush(chain)
      sudo %{/bin/sh -c "#{flush_commands(chain).join(' && ')}"}
    end

    def flush_commands(chain)
      [
        # Create a new chain if it doesn't exist or flush it if it does
        %{(/sbin/iptables -N #{chain} || /sbin/iptables -F #{chain})},

        # If this chain isn't jumped to from INPUT, let's make it so
        %{(/sbin/iptables -L INPUT | grep -cq #{chain} || /sbin/iptables -I INPUT -j #{chain})}
      ]
    end

    def enable_commands(chain, port, protocol, options = {})
      if from_roles = (options[:from_role] || options[:from_roles])
        servers = find_servers(:roles => from_roles, :skip_hostfilter => true).collect do |server|
          IPSocket.getaddress(server.host)
        end

        servers.flatten.uniq.collect do |ip_address|
          %{/sbin/iptables -A #{chain} -p #{protocol} -m #{protocol} -s #{ip_address} --dport #{port} -j ACCEPT}
        end
      else
        [ %{/sbin/iptables -A #{chain} -p #{protocol} -m #{protocol} --dport #{port} -j ACCEPT} ]
      end
    end

    def save
      sudo %{/etc/rc.d/init.d/iptables save}
    end
  end
end
