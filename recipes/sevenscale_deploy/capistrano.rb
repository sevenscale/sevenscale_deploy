namespace :capistrano do
  after 'deploy:finalize_update', 'capistrano:write_roles'
  after 'deploy:finalize_update', 'capistrano:write_servers'

  desc 'Write roles config file'
  task :write_roles do
    config_hash = {}

    roles.each do |role_name, servers|
      config_hash[role_name] = servers.collect { |s| s.host }
    end

    put YAML::dump(config_hash), "#{shared_path}/config/capistrano_roles.yml"
    run "ln -s #{shared_path}/config/capistrano_roles.yml #{release_path}/config/capistrano_roles.yml"
  end

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
    run "ln -s #{shared_path}/config/capistrano_servers.yml #{release_path}/config/capistrano_servers.yml"
  end
end