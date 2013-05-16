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

namespace :iptables do
  def rules
    @@rules ||= Hash.new { |h,role| h[role] = [] }
  end

  def alternate_hostnames
    @@alternate_hostnames ||= Hash.new { |h,host| h[host] = [] }
  end

  def alternate_hostname(host, *alternates)
    alternate_hostnames[host] += alternates.flatten
  end

  namespace :apply do
    desc "Apply all iptables settings"
    task :default do
      tasks.each do |name, task|
        execute_task(task) unless task == default_task
      end
    end
  end

  def all(*args)
    role(:all, *args)
  end

  def role(role, *ports)
    options   = ports.last.is_a?(Hash) ? ports.pop : {}

    generate_rule(role)

    if ports.empty? && !options.empty?
      iptables.rules[role.to_sym] << options
    else
      ports.each do |port|
        iptables.rules[role.to_sym] << options.merge({ :port => port })
      end
    end
  end

  def generate_rule(role)
    task_opts = role == :all ? {} : { :roles => role }

    namespace :apply do
      desc "Apply iptables rules for #{role}"
      task role, task_opts do
        chain_prefix = "#{fetch(:application).upcase}-#{role.to_s.upcase}"
        chain = "#{chain_prefix[0..23]}-INPUT"

        commands = iptables.flush_commands(chain)

        commands += iptables.rules[role.to_sym].collect do |rule|
          iptables.enable_commands(chain, rule)
        end

        sudo %{/bin/sh -c "#{commands.flatten.join(' && ')}"}

        iptables.save
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

  def enable_commands(chain, options)
    if options[:interface]
      enable_interface(chain, options[:interface], options)
    else
      enable_port(chain, options[:port], options[:protocol], options)
    end
  end

  def enable_interface(chain, interface, options = {})
    [ %{/sbin/iptables -A #{chain} -i #{interface} -j ACCEPT} ]
  end

  def enable_port(chain, port, protocol, options = {})
    protocol ||= 'tcp'

    servers = []
    
    if options[:from_all]
      servers += find_servers(:skip_hostfilter => true).collect do |server|
        [ server.host, Array(server.options[:ips]) ].flatten.uniq.collect do |host|
          IPSocket.getaddress(host)
        end
      end
    elsif from_roles = (options[:from_role] || options[:from_roles])
      servers += find_servers(:roles => from_roles, :skip_hostfilter => true).collect do |server|
        [ server.host, Array(server.options[:ips]) ].flatten.uniq.collect do |host|
          IPSocket.getaddress(host)
        end
      end
    end

    if from_hosts = (options[:from_host] || options[:from_hosts])
      servers += Array(from_hosts).collect do |host|
        Array(host).flatten.uniq.collect do |host|
          IPSocket.getaddress(host) rescue host
        end
      end
    end

    if servers.length > 0
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
