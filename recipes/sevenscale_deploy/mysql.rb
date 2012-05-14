namespace :mysql do
  desc "Enable mysql on boot and start"
  task :enable, :roles => :db do
    sudo "/sbin/chkconfig mysqld on"
    sudo "/etc/rc.d/init.d/mysqld start"
  end

  desc "Create database"
  task :create, :roles => :db, :only => { :primary => true } do
    db_root_user     = fetch(:db_root_user, 'root')
    db_root_password = fetch(:db_root_password, nil)

    db_user     = fetch(:db_user)     { fetch(:user) }
    db_password = fetch(:db_password) { fetch(:password) }
    db_name     = fetch(:db_name)     { fetch(:application) }

    mysql_commands = []
    mysql_commands << %{CREATE DATABASE #{db_name};}

    mysql_commands.each do |command|
      mysql_auth = "-u#{db_root_user}"
      mysql_auth << " -p" if db_root_password

      run %(mysql #{mysql_auth} -e "#{command}") do |ch, stream, out|
        ch.send_data "#{db_root_password}\n" if out=~ /^Enter password:/
      end
    end
  end

  desc "Grant database access to all hosts"
  task :grant, :roles => :db, :only => { :primary => true } do
    grant_for_database
  end

  desc "Download database dump"
  task :dump_to_local, :roles => :db, :only => { :primary => true } do
    dump

    download fetch(:backup_file), "tmp/#{File.basename(fetch(:backup_file))}"
  end

  desc "Clone remote database to local database"
  task :clone_to_local, :roles => :db, :only => { :primary => true } do
    local_rails_env      = fetch(:local_rails_env, "development")
    database_environment = YAML::load(ERB.new(IO.read("config/database.yml")).result)[local_rails_env]

    dump

    download fetch(:backup_file), "tmp/#{File.basename(fetch(:backup_file))}"

    mysql_command = "mysql -u #{database_environment['username']}"
    mysql_command << " --password='#{database_environment['password']}'" if database_environment['password']
    mysql_command << " -h #{database_environment['host']}"               if database_environment['host']
    mysql_command << " #{database_environment['database']}"

    full_command = %{bzip2 -cd tmp/#{File.basename(fetch(:backup_file))} | #{mysql_command}}
    logger.debug %{locally executing "#{full_command}"}
    logger.debug %x{#{full_command}}
  end

  desc "Create database backup of all databases"
  task :backup, :roles => :db, :only => { :primary => true } do
    db_root_user     = fetch(:db_root_user, 'root')
    db_root_password = fetch(:db_root_password, nil)

    time_string          = Time.now.strftime("%Y%m%d-%H%M%S")
    remote_filename      = "mysqldump-all-#{time_string}.sql"
    full_remote_filename = "#{shared_path}/db_backups/#{remote_filename}"

    cmd = %{mkdir -p #{shared_path}/db_backups; mysqldump -u"#{db_root_user}" -p --all-databases --add-drop-database --create-options --flush-privileges -r #{full_remote_filename} && bzip2 -9 #{full_remote_filename}}

    run cmd do |ch, stream, out|
      ch.send_data "#{db_root_password}\n" if out=~ /^Enter password:/
    end

    set :backup_file, "#{full_remote_filename}.bz2"
  end

  desc "Create database dump"
  task :dump, :roles => :db, :only => { :primary => true } do
    db_user     = fetch(:db_user)     { fetch(:user) }
    db_password = fetch(:db_password) { fetch(:password) }
    db_name     = fetch(:db_name)     { fetch(:application) }

    time_string          = Time.now.strftime("%Y%m%d-%H%M%S")
    remote_filename      = "mysqldump-#{application}-#{time_string}.sql"
    full_remote_filename = "#{shared_path}/db_backups/#{remote_filename}"

    cmd = %{mkdir -p #{shared_path}/db_backups; mysqldump --add-drop-table -u"#{db_user}" -p "#{db_name}" -r #{full_remote_filename} && bzip2 -9 #{full_remote_filename}}

    run cmd do |ch, stream, out|
      ch.send_data "#{db_password}\n" if out=~ /^Enter password:/
    end

    set :backup_file, "#{full_remote_filename}.bz2"
  end

  def grant_for_database(options = {})
    options = options.symbolize_keys

    db_root_user     = options[:root_user]          || fetch(:db_root_user, 'root')
    db_root_password = options[:root_password]      || fetch(:db_root_password, nil)
    db_user          = options[:username]           || fetch(:db_user)     { fetch(:user) }
    db_password      = options[:password]           || fetch(:db_password) { fetch(:password) }
    db_name          = options[:database]           || fetch(:db_name)     { fetch(:application) }
    db_host          = options.delete(:run_on_host) || options[:host]
    db_privs         = options[:privileges]         || 'ALL PRIVILEGES'

    servers = self.roles.values.collect do |role|
      role.servers.collect do |server|
        [ server.host, Array(server.options[:ips]) ].flatten.uniq.collect do |host|
          if fetch(:mysql_only_grant_ips, false)
            IPSocket.getaddress(host)
          else
            [ host, IPSocket.getaddress(host) ]
          end
        end
      end
    end.flatten.uniq

    # Make sure we include localhost
    servers += %w(localhost 127.0.0.1)

    mysql_commands = []

    servers.each do |server|
      mysql_commands << %{GRANT #{db_privs} ON #{db_name}.* TO '#{db_user}'@'#{server}' IDENTIFIED BY '#{db_password}';}
    end
    mysql_commands << %{FLUSH PRIVILEGES;}

    mysql_commands.each do |command|
      mysql_auth = "-u#{db_root_user}"
      mysql_auth << " -p" if db_root_password

      run %(mysql #{mysql_auth} -e "#{command}"), :hosts => db_host do |ch, stream, out|
        ch.send_data "#{db_root_password}\n" if out=~ /^Enter password:/
      end
    end
  end
end
