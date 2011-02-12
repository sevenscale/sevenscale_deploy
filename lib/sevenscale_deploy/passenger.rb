module SevenScaleDeploy
  module Passenger
    def self.included(manifest)
      manifest.configure :apache => {
        :keep_alive => 'Off',
        :max_keep_alive_requests => 100,
        :keep_alive_timeout => 15,
        :max_clients => 150,
        :server_limit => 16,
        :timeout => 300,
        :trace_enable => 'On',
        :gzip => false,
        :gzip_types => ['text/html', 'text/plain', 'text/xml', 'text/css', 'application/x-javascript', 'application/javascript']
      }
      manifest.configure :passenger => {}
    end

    def passenger
      recipe :passenger_gem
      recipe :passenger_apache_module
    end

    def passenger_gem(options = {})
      package 'libcurl-devel', :ensure => :installed

      package "passenger", :ensure => (options[:version] || :latest), :provider => :gem,
        :require => [
          package('libcurl-devel')
        ]
    end

    def passenger_apache_module(options = {})
      recipe :httpd_development_libraries

      httpd_conf_dir = options[:httpd_conf_dir] || '/etc/httpd/conf.d'

      exec "passenger-install-apache2-module",
        :command => "passenger-install-apache2-module --auto",
        :subscribe => package('passenger'),
        :refreshonly => true,
        :require => [ package('apr-devel'), package('apache2') ]

      exec "write passenger.conf",
        :command => "passenger-install-apache2-module --snippet > #{File.join(httpd_conf_dir, 'passenger.conf')}",
        :subscribe => exec('passenger-install-apache2-module'),
        :refreshonly => true,
        :notify => service('apache2')
    end

    def apache(options = {})
      package 'apache2', :name => 'httpd', :ensure => options[:version] || :installed
      package 'mod_ssl', :ensure => :installed, :require => package('apache2')

      service "apache2",
        :name => 'httpd',
        :pattern => 'httpd',
        :ensure => :running,
        :enable => true,
        :require => [ package('apache2'), package('mod_ssl') ]
    end
  end
end