Capistrano::Configuration.instance(:must_exist).load do
  namespace :apache do
    # after 'deploy:update_code', 'apache:config'
    
    desc "Enable apache on boot and start"
    task :enable, :roles => :app, :only => { :apache => true } do
      sudo "/sbin/chkconfig httpd on"
      sudo "/etc/rc.d/init.d/httpd start"
    end

    desc "Restart apache"
    task :restart, :roles => :app, :only => { :apache => true } do
      sudo "/etc/rc.d/init.d/httpd restart"
    end

    desc "Setup SELinux to allow httpd to proxy"
    task :selinux, :roles => :app, :only => { :apache => true } do
      sudo "/usr/sbin/setsebool -P httpd_can_network_connect on"
    end

    desc "Deploy configuration"
    task :config, :roles => :app, :only => { :apache => true } do
      mongrel_port_base     = fetch(:mongrel_base_port, 5000)
      mongrel_instances     = fetch(:mongrel_instances, 3)
      apache_admin_email    = fetch(:apache_admin_email, 'noone@nowhere.local')
      apache_server_name    = fetch(:apache_server_name, 'site.local')
      apache_server_aliases = Array(fetch(:apache_server_aliases, []))
      apache_server_port    = fetch(:apache_server_port, 80)
      rails_env             = fetch(:rails_env, "production")

      ports = []
      1.upto(mongrel_instances) { |idx| ports << mongrel_port_base + idx - 1 }

      apache_config = ERB.new(File.read('cap/assets/apache.conf'), nil, '-')
      put apache_config.result(binding), "#{latest_release}/tmp/#{application}.conf"
      sudo "cp #{latest_release}/tmp/#{application}.conf /etc/httpd/conf.d/#{application}.conf"
    end
  end
end