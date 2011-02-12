module SevenScaleDeploy
  module StandardPackages
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
    end

    # Install ntp and enables the ntp service.
    def ntp
      package 'ntp', :ensure => :installed

      service 'ntp',
        :name => Facter.case(:operatingsystem, 'Ubuntu' => 'ntp', 'Fedora' => 'ntpd', 'RedHat' => 'ntpd', 'CentOS' => 'ntpd', :default => 'ntp'),
        :ensure => :running, :enable => true, :require => package('ntp'), :pattern => 'ntpd'
    end

    def god
      package 'god', :provider => :gem, :ensure => :installed
    end

    def sendmail
      package 'sendmail', :ensure => :installed
      service 'sendmail', :ensure => :running, :enable => true, :require => package('sendmail')
    end

    def mysql_libraries
      case Facter.operatingsystem
      when 'RedHat', 'CentOS'
        package 'mysql-devel', :ensure => :installed
      when 'Fedora'
        package 'mysql-libs',  :ensure => :installed
        package 'mysql-devel', :ensure => :installed
      end
    end

    def mysql_gem
      case Facter.operatingsystem
      when 'RedHat', 'CentOS'
        package 'mysql-gem', :name => 'mysql', :provider => :gem, :ensure => :installed,
          :require => [ package('mysql-devel') ]
      when 'Fedora'
        package 'mysql-gem', :name => 'mysql', :provider => :gem, :ensure => :installed,
          :require => [ package('mysql-devel'), package('mysql-libs') ]
      end
    end

    def httpd_development_libraries
      package 'httpd-devel', :ensure => :installed
      package 'apr-devel',   :ensure => :installed
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

    def build_tools
      package 'patch', :ensure => :installed
    end

    def nfs_services
      package 'nfs-utils', :ensure => :installed
      package 'rpcbind',   :ensure => :installed

      service 'nfs',     :ensure => :running, :enable => true, :require => package('nfs-utils')
      service 'nfslock', :ensure => :running, :enable => true, :require => [ package('nfs-utils'), service('rpcbind'), service('nfs') ], :pattern => 'lockd'
      service 'rpcbind', :ensure => :running, :enable => true, :require => package('rpcbind')
    end

    def nokogiri_gem_dependencies(options = {})
      package 'libxml2',       options.reverse_merge(:ensure => :installed)
      package 'libxml2-devel', options.reverse_merge(:ensure => :installed)
      package 'libxslt',       options.reverse_merge(:ensure => :installed)
      package 'libxslt-devel', options.reverse_merge(:ensure => :installed)
    end

    def typhoeus_gem_dependencies(options = {})
      case Facter.operatingsystem
      when 'RedHat', 'CentOS'
        package 'curl-devel', options.reverse_merge(:ensure => :installed)
      when 'Fedora'
        case Facter.operatingsystemrelease
        when '8'
          package 'curl-devel', options.reverse_merge(:ensure => :installed)
        else
          package 'libcurl',       options.reverse_merge(:ensure => :installed)
          package 'libcurl-devel', options.reverse_merge(:ensure => :installed)
        end
      end
    end

    def oniguruma_gem_dependencies(options = {})
      package 'oniguruma',       options.reverse_merge(:ensure => :installed)
      package 'oniguruma-devel', options.reverse_merge(:ensure => :installed)
    end

    def iostat
      package 'sysstat', :ensure => :installed
    end
  end
end