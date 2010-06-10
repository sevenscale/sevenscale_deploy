##
## Add :skip_hostfilter to find_servers
##
::Capistrano::Configuration.class_eval do
  def find_servers(options={})
    hosts  = server_list_from(ENV['HOSTS'] || options[:hosts])

    if hosts.any?
      if options[:skip_hostfilter]
        hosts.uniq
      else
        filter_server_list(hosts.uniq)
      end
    else
      roles  = role_list_from(ENV['ROLES'] || options[:roles] || self.roles.keys)
      only   = options[:only] || {}
      except = options[:except] || {}

      servers = roles.inject([]) { |list, role| list.concat(self.roles[role]) }
      servers = servers.select { |server| only.all? { |key,value| server.options[key] == value } }
      servers = servers.reject { |server| except.any? { |key,value| server.options[key] == value } }

      if options[:skip_hostfilter]
        servers.uniq
      else
        filter_server_list(servers.uniq)
      end
    end
  end
end