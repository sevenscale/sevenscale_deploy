namespace :capistrano do
  after 'deploy:finalize_update', 'capistrano:write_servers'
  after 'deploy:finalize_update', 'capistrano:write_capistrano_variables'

  desc 'Write servers config file'
  task :write_servers do
    config_hash = {}
    config_hash['roles'] = {}
    config_hash['options'] = {}

    roles.each do |role_name, servers|
      config_hash['roles'][role_name] = servers.collect { |s| s.host }

      servers.each do |server|
        config_hash['options'][server.host] ||= {}
        config_hash['options'][server.host].merge!(server.options)
      end
    end

    put YAML::dump(config_hash), "#{shared_path}/config/capistrano_servers.yml"
    run "ln -nsf #{shared_path}/config/capistrano_servers.yml #{release_path}/config/capistrano_servers.yml"
  end


  desc 'Write capistano configuration settings'
  task :write_capistrano_variables do
    config_hash = {}
    variables.each do |key, value|
      # Don't assign variables that are procs -- they haven't been turned 
      # into real values yet
      config_hash[key] = value unless value.respond_to?(:call)
    end

    config_hash['roles'] = {}
    config_hash['server_options'] = {}

    roles.each do |role_name, servers|
      config_hash['roles'][role_name] = servers.collect { |s| s.host }

      servers.each do |server|
        config_hash['server_options'][server.host] ||= {}
        config_hash['server_options'][server.host].merge!(server.options)
      end
    end

    put YAML::dump(config_hash), "#{release_path}/config/capistrano_variables.yml"
  end
end