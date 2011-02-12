module SevenScaleDeploy
  module Passenger
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
  end
end