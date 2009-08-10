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

    def role(role, port, options = {})
      task_opts = role == :all ? {} : { :roles => role }
      
      iptables.rules[role.to_sym] << options.merge({ :port => port })
      
      namespace :apply do
        desc "Allow port #{port}/#{options[:protocol] || 'tcp'} in iptables"
        task role, task_opts do
          chain_prefix = "#{fetch(:application).upcase}-#{role.to_s.upcase}"
          chain = "#{chain_prefix[0..23]}-INPUT"
          
          iptables.flush(chain)
          
          iptables.rules[role.to_sym].each do |rule|
            iptables.enable(chain, rule[:port], rule[:protocol] || 'tcp')
          end
          
          iptables.save
        end
      end
      
    end
    
    def enable(chain, port, protocol, options = {})
      if from_roles = (options[:from_role] || options[:from_roles])
        servers = find_servers(:roles => from_roles).collect do |server| 
          IPSocket.getaddress(server.host)
        end

        servers.flatten.uniq.each do |ip_address|
          sudo %{/sbin/iptables -A #{chain} -p #{protocol} -m #{protocol} -s #{ip_address} --dport #{port} -j ACCEPT}
        end
      else
        sudo %{/sbin/iptables -A #{chain} -p #{protocol} -m #{protocol} --dport #{port} -j ACCEPT}
      end
    end
    
    def flush(chain)
      # Create a new chain if it doesn't exist or flush it if it does
      sudo %{/bin/sh -c "/sbin/iptables -N #{chain} || /sbin/iptables -F #{chain}"}
      
      # If this chain isn't jumped to from INPUT, let's make it so
      sudo %{/bin/sh -c "/sbin/iptables -L INPUT | grep -cq #{chain} || #{sudo} /sbin/iptables -I INPUT -j #{chain}"}
    end
    
    def save
      sudo %{/etc/rc.d/init.d/iptables save}
    end
  end
end