namespace :db do
  after "deploy:update_code", 'db:create_config'
  after "deploy:update_code", 'db:symlink'

  desc "Deploy database.yml"
  task :create_config do
    db_user     = fetch(:db_user)     { fetch(:user) }
    db_password = fetch(:db_password) { fetch(:password) }
    db_name     = fetch(:db_name)     { fetch(:application) }
    db_adapter  = fetch(:db_adapter, 'mysql')
    db_pool     = fetch(:db_pool, 5)
    db_options  = fetch(:db_options, {})
    rails_env   = fetch(:rails_env, 'production')
    db_envs     = fetch(:db_envs, {})

    unless primary_db_host = fetch(:db_host, nil)
      begin
        primary_db_host = find_servers(:roles => :db, :only => { :primary => true }, :skip_hostfilter => true).first.host
        all_db_hosts    = find_servers(:roles => :db, :skip_hostfilter => true).collect { |s| s.host }.uniq
      rescue ArgumentError
        logger.info "*** Skipping db:create_config -- we don't have any :db hosts"
        # If we don't have any :db's, let's just not
        next
      end
    end

    all_db_hosts ||= [ primary_db_host ]

    database_yml = {}
    database_spec = database_yml[rails_env] = db_options.dup

    database_spec['adapter']  = db_adapter
    database_spec['username'] = db_user
    database_spec['password'] = db_password
    database_spec['database'] = db_name
    database_spec['host']     = primary_db_host
    database_spec['pool']     = db_pool

    all_db_hosts.each do |db_host|
      host_spec = database_spec[db_host] = db_options.dup

      host_spec['adapter']  = db_adapter
      host_spec['username'] = db_user
      host_spec['password'] = db_password
      host_spec['database'] = db_name
      host_spec['host']     = db_host
      host_spec['pool']     = db_pool
    end

    db_envs.each do |name, env|
      host_spec = database_spec[name.to_s] = db_options.dup

      host_spec['adapter']  = db_adapter
      host_spec['username'] = db_user
      host_spec['password'] = db_password
      host_spec['database'] = db_name
      host_spec['host']     = db_host
      host_spec['pool']     = db_pool

      # Overrides
      host_spec.merge!(env.to_hash)
    end

    run "mkdir -p #{shared_path}/config"
    put YAML::dump(database_yml), "#{shared_path}/config/database.yml", :mode => 0664
  end

  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
  end

  desc "Create database"
  task :create, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).create
  end

  desc "Grant database access to all hosts"
  task :grant, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).grant
  end

  desc "Create database dump"
  task :dump, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).dump
  end

  desc "Download database dump"
  task :dump_to_local, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).dump_to_local
  end

  desc "Clone remote database to local database"
  task :clone_to_local, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).dump_to_local
  end

  desc "Create database backup of all databases"
  task :backup, :roles => :db, :only => { :primary => true } do
    send(fetch(:db_adapter, 'mysql')).backup
  end
end
