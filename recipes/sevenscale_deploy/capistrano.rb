namespace :capistrano do
  after 'deploy:finalize_update', 'capistrano:write_roles'

  desc 'Write roles config file'
  task :write_roles do
    config_hash = {}

    roles.each do |role_name, servers|
      config_hash[role_name] = servers.collect { |s| s.host }
    end

    put YAML::dump(config_hash), "#{shared_path}/config/capistrano_roles.yml"
  end
end