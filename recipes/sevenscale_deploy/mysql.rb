Capistrano::Configuration.instance(:must_exist).load do
  namespace :mysql do
    desc "Enable mysql on boot and start"
    task :enable, :roles => :db do
      sudo "/sbin/chkconfig mysqld on"
      sudo "/etc/rc.d/init.d/mysqld start"
    end

    desc "Create database"
    task :create, :roles => :db do
      db_root_user     = fetch(:db_root_user, 'root')
      db_root_password = fetch(:db_root_password, nil)

      db_user     = fetch(:db_user)     { fetch(:user) }
      db_password = fetch(:db_password) { fetch(:password) }
      db_name     = fetch(:db_name)     { fetch(:application) }

      mysql_commands = []
      mysql_commands << %{CREATE DATABASE #{db_name};}
      mysql_commands << %{GRANT ALL PRIVILEGES ON #{db_name}.* TO '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}';}
      mysql_commands << %{FLUSH PRIVILEGES;}

      mysql_commands.each do |command|
        mysql_auth = "-u#{db_root_user}"
        mysql_auth << " -p'#{db_root_password}'" if db_root_password
        run %(mysql #{mysql_auth} -e "#{command}")
      end
    end

    desc "Grant database access to all hosts"
    task :grant, :roles => :db do
      db_root_user     = fetch(:db_root_user, 'root')
      db_root_password = fetch(:db_root_password, nil)

      db_user     = fetch(:db_user)     { fetch(:user) }
      db_password = fetch(:db_password) { fetch(:password) }
      db_name     = fetch(:db_name)     { fetch(:application) }

      servers = self.roles.values.collect do |role|
        role.servers.collect do |server|
          [ server.host, IPSocket.getaddress(server.host) ]
        end
      end.flatten.uniq

      mysql_commands = []

      servers.each do |server|
        mysql_commands << %{GRANT ALL PRIVILEGES ON #{db_name}.* TO '#{db_user}'@'#{server}' IDENTIFIED BY '#{db_password}';}
      end
      mysql_commands << %{FLUSH PRIVILEGES;}

      mysql_commands.each do |command|
        mysql_auth = "-u#{db_root_user}"
        mysql_auth << " -p'#{db_root_password}'" if db_root_password
        run %(mysql #{mysql_auth} -e "#{command}")
      end
    end

    desc "Download database dump"
    task :download, :roles => :db, :only => { :primary => true } do
      dump

      download fetch(:backup_file), "tmp/#{File.basename(fetch(:backup_file))}"
    end

    desc "Create database backup of all databases"
    task :backup, :roles => :db, :only => { :primary => true } do
      db_root_user     = fetch(:db_root_user, 'root')
      db_root_password = fetch(:db_root_password, nil)

      time_string          = Time.now.strftime("%Y%m%d-%H%M%S")
      remote_filename      = "mysqldump-all-#{time_string}.sql"
      full_remote_filename = "#{shared_path}/db_backups/#{remote_filename}"

      cmd = %{mkdir -p #{shared_path}/db_backups; mysqldump -u"#{db_root_user}" -p --all-databases --add-drop-database --create-options --flush-privileges -r #{full_remote_filename} && bzip2 -9 #{full_remote_filename}}

      run cmd do |ch, stream, out |
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

      cmd = %{mkdir -p #{shared_path}/db_backups; mysqldump --add-drop-table -u"#{db_user}" -p "#{application}" -r #{full_remote_filename} && bzip2 -9 #{full_remote_filename}}

      run cmd do |ch, stream, out |
         ch.send_data "#{db_password}\n" if out=~ /^Enter password:/
      end

      set :backup_file, "#{full_remote_filename}.bz2"
    end
  end
end