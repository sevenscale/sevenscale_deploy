namespace :capistrano do
  before 'deploy:finalize_update', 'capistrano:write_servers'
  before 'deploy:finalize_update', 'capistrano:write_capistrano_variables'

  desc 'Write servers config file'
  task :write_servers, :except => { :no_release => true } do
    next if fetch(:no_capistrano_servers_yml, false)

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

    run "mkdir -p #{shared_path}/config"
    put YAML::dump(config_hash), "#{shared_path}/config/capistrano_servers.yml"
    run "ln -nsf #{shared_path}/config/capistrano_servers.yml #{release_path}/config/capistrano_servers.yml"
  end


  desc 'Write capistano configuration settings'
  task :write_capistrano_variables, :except => { :no_release => true } do
    config_hash = {}

    basic_types = lambda do |v|
      case v
      when String, Numeric, Symbol, true, false
        true
      when Array
        v.all? { |vv| basic_types.call(vv) }
      else
        false
      end
    end

    variables.each do |key, value|
      # Don't assign variables that are procs -- they haven't been turned 
      # into real values yet
      config_hash[key] = value if basic_types.call(value)
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
