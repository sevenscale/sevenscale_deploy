Capistrano::Configuration.instance(:must_exist).load do
  namespace :mysql do
    desc "Enable mysql on boot and start"
    task :enable, :roles => :db do
      sudo "/sbin/chkconfig mysqld on"
      sudo "/etc/rc.d/init.d/mysqld start"
    end
    
    desc "Create database"
    task :create, :roles => :db do
      db_root_user     = fetch('db_root_user', 'root')
      db_root_password = fetch('db_root_password', nil)
      
      db_user     = fetch('db_user') { fetch(:user) }
      db_password = fetch('db_password') { fetch(:password) }
      application = fetch('application')

      mysql_commands = []
      mysql_commands <<  %{CREATE DATABASE #{application};}
      mysql_commands << %{GRANT ALL PRIVILEGES ON #{application}.* TO '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}';}
      mysql_commands << %{FLUSH PRIVILEGES;}

      mysql_commands.each do |command|
        mysql_auth = "-u#{db_root_user}"
        mysql_auth << " -p'#{db_root_password}'" if db_root_password
        run %(mysql #{mysql_auth} -e "#{command}")
      end
    end

    desc "Grant database access to all hosts"
    task :grant, :roles => :db do
      db_root_user     = fetch('db_root_user', 'root')
      db_root_password = fetch('db_root_password', nil)

      db_user     = fetch('db_user')     { fetch(:user) }
      db_password = fetch('db_password') { fetch(:password) }
      application = fetch('application')

      servers = self.roles.values.collect do |role| 
        role.servers.collect do |server| 
          [ server.host, IPSocket.getaddress(server.host) ]
        end
      end.flatten.uniq 

      mysql_commands = []

      servers.each do |server|
        mysql_commands << %{GRANT ALL PRIVILEGES ON #{application}.* TO '#{db_user}'@'#{server}' IDENTIFIED BY '#{db_password}';}
      end
      mysql_commands << %{FLUSH PRIVILEGES;}

      mysql_commands.each do |command|
        mysql_auth = "-u#{db_root_user}"
        mysql_auth << " -p'#{db_root_password}'" if db_root_password
        run %(mysql #{mysql_auth} -e "#{command}")
      end
    end

    desc "Create database dump"
    task :dump, :roles => :db, :only => { :primary => true } do
      db_user     = fetch('db_user') { fetch(:user) }
      db_password = fetch('db_password') { fetch(:password) }
      application = fetch('application')

      time_string = Time.now.strftime("%Y%m%d-%H%M%S")

      dump_files = Hash.new do |h,k|
        filename = File.join('tmp', "mysqldump-#{k}-#{time_string}.sql.gz")
        puts "Writing to #{filename}"
        h[k] = File.open(filename, IO::EXCL | IO::WRONLY | IO::CREAT)
      end

      remote_filename = "mysqldump-$CAPISTRANO:HOST$-#{time_string}.sql.gz"

      cmd = %{mysqldump -u"#{db_user}" -p "#{application}" | gzip -c9 > /tmp/#{remote_filename}}

      user_management.run_with_input cmd, /Enter password/, db_password
      download "/tmp/#{remote_filename}", "tmp/#{remote_filename}"
      run %{rm /tmp/#{remote_filename}}
    end
  end
end