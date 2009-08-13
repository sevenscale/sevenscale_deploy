Capistrano::Configuration.instance(:must_exist).load do
  namespace :passenger do
    after 'deploy:update_code', 'passenger:config'

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

    desc "Reload Apache config"
    task :reload, :only => { :passenger => true } do
      apache.reload
    end

    desc "Install Passenger"
    task :install, :only => { :passenger => true } do
      sudo "passenger-install-apache2-module --auto"
    end

    desc "Configure Passenger"
    task :update_config, :only => { :passenger => true } do

      passenger_root = fetch(:passenger_root) { capture("passenger-config --root").chomp }
      ruby_path      = fetch(:ruby)           { capture("/usr/bin/whereis -b ruby")[/ruby: ([^ ]+)/, 1] }

      passenger_config =<<-EOF
        LoadModule passenger_module #{passenger_root}/ext/apache2/mod_passenger.so
        PassengerRoot #{passenger_root}
        PassengerRuby #{ruby_path}
      EOF

      passenger_config_file = "/tmp/.passenger.conf.#{$$}"

      put passenger_config, passenger_config_file
      sudo "cp #{passenger_config_file} /etc/httpd/conf.d/passenger.conf && rm -f #{passenger_config_file}"
      apache.restart
    end

    desc "Deploy configuration"
    task :config, :roles => :app, :only => { :passenger => true } do
      configuration = {}
      configuration[:domain]         = fetch(:apache_server_name)
      configuration[:domain_aliases] = fetch(:apache_server_aliases)
      configuration[:deploy_to]      = current_path

      configuration[:passenger] = {}
      configuration[:passenger][:rails_env] = fetch(:rails_env, "production")

      configuration[:ssl] = {}
      configuration[:ssl][:certificate_file]     = fetch(:apache_ssl_certificate_file)
      configuration[:ssl][:certificate_key_file] = fetch(:apache_ssl_certificate_key_file)

      configuration[:apache] = {}

      filename = File.join(File.dirname(__FILE__), 'assets/passenger.conf')

      apache_config = ERB.new(File.read(filename), nil, '-')
      put apache_config.result(binding), "#{latest_release}/tmp/#{application}.conf"
      sudo "cp #{latest_release}/tmp/#{application}.conf /etc/httpd/conf.d/#{application}.conf"

      # Reload apache config
      reload
    end
    
    def passenger_config_boolean(key)
      if key.nil?
        nil
      elsif key == 'Off' || (!!key) == false
        'Off'
      else
        'On'
      end
    end
  end
end
