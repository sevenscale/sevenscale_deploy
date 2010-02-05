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
    rails_env   = fetch(:rails_env, 'production')

    use_seamless_database_pool = fetch(:use_seamless_database_pool, false)

    primary_db_host = find_servers(:roles => :db, :only => { :primary => true }, :skip_hostfilter => true).first.host

    database_yml = {}
    database_spec = database_yml[rails_env] = {}

    database_spec['adapter']  = db_adapter
    database_spec['username'] = db_user
    database_spec['password'] = db_password
    database_spec['database'] = db_name
    database_spec['host']     = primary_db_host
    database_spec['pool']     = db_pool

    if use_seamless_database_pool
      all_db_hosts = find_servers(:roles => :db, :skip_hostfilter => true).collect { |s| s.host }.uniq

      database_spec['pool_adapter'] = database_spec['adapter']
      database_spec['adapter']      = 'seamless_database_pool'
      database_spec['master']       = { 'host' => primary_db_host }
      database_spec['read_pool']    = all_db_hosts.collect { |host| { 'host' => host } }
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
