Capistrano::Configuration.instance(:must_exist).load do
  namespace :db do
    after "deploy:update_code", 'db:create_config'
    after "deploy:update_code", 'db:symlink'

    desc "Deploy database.yml"
    task :create_config do
      db_user     = fetch(:db_user)     { fetch(:user) }
      db_password = fetch(:db_password) { fetch(:password) }
      db_name     = fetch(:db_name)     { fetch(:application) }
      db_adapter  = fetch(:db_adapter, 'mysql')
      rails_env   = fetch(:rails_env, 'production')
      
      use_seamless_database_pool = fetch(:use_seamless_database_pool, false)

      primary_db_host = find_servers(:roles => :db, :only => { :primary => true }).first.host

      database_yml = {}
      database_spec = database_yml[rails_env] = {}
      
      database_spec['adapter']  = db_adapter
      database_spec['username'] = db_user
      database_spec['password'] = db_password
      database_spec['database'] = db_name
      database_spec['host']     = primary_db_host
      
      if use_seamless_database_pool
        all_db_hosts = find_servers(:roles => :db).collect { |s| s.host }.uniq

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
    
    desc "Create database dump"
    task :dump, :roles => :db, :only => { :primary => true } do
      db_user     = fetch(:db_user)     { fetch(:user) }
      db_password = fetch(:db_password) { fetch(:password) }
      db_name     = fetch(:db_name)     { fetch(:application) }
      
      primary_db_host = find_servers(:roles => :db, :only => { :primary => true }).first.host
      
      time_string = Time.now.strftime("%Y%m%d-%H%M%S")
      
      dump_files = Hash.new do |h,k|
        filename = File.join('tmp', "mysqldump-#{k}-#{time_string}.sql.gz")
        puts "Writing to #{filename}"
        h[k] = File.open(filename, IO::EXCL | IO::WRONLY | IO::CREAT)
      end
      
      remote_filename = "mysqldump-$CAPISTRANO:HOST$-#{time_string}.sql.gz"
      
      cmd = %{mysqldump -u"#{db_user}" -p "#{db_name}" -h $CAPISTRANO:HOST$ | gzip -c9 > /tmp/#{remote_filename}}
      
      user_management.run_with_input cmd, /Enter password/, db_password
      download "/tmp/#{remote_filename}", "tmp/#{remote_filename}"
      run %{rm /tmp/#{remote_filename}}
    end
  end
end
