Capistrano::Configuration.instance(:must_exist).load do
  namespace :passenger do
    # after 'deploy:update_code', 'passenger:config'
    
    desc "[passenger] Start Application (nothing)"
    task :start, :roles => :app, :only => { :passenger => true } do
      # nothing
    end

    desc "[passenger] Stop Application (nothing)"
    task :stop, :roles => :app, :only => { :passenger => true } do
      # nothing
    end

    desc "Restart Application"
    task :restart, :roles => :app, :only => { :passenger => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end
    
    desc "Deploy configuration"
    task :config, :roles => :app, :only => { :passenger => true } do
      apache_admin_email    = fetch(:apache_admin_email, 'noone@nowhere.local')
      apache_server_name    = fetch(:apache_server_name, 'site.local')
      apache_server_aliases = Array(fetch(:apache_server_aliases, []))
      apache_server_port    = fetch(:apache_server_port, 80)
      rails_env             = fetch(:rails_env, "production")

      apache_config = ERB.new(File.read('cap/assets/passenger.conf'), nil, '-')
      put apache_config.result(binding), "#{latest_release}/tmp/#{application}.conf"
      sudo "cp #{latest_release}/tmp/#{application}.conf /etc/httpd/conf.d/#{application}.conf"
    end
  end
end