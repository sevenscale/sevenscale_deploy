module SevenScaleDeploy
  module StandardPackages
    # Install ntp and enables the ntp service.
    def ntp(options = {})
      package 'ntp', :ensure => :installed

      enabled = options[:enabled] != false

      service 'ntp',
        :name => Facter.case(:operatingsystem, 'Ubuntu' => 'ntp', 'Fedora' => 'ntpd', 'RedHat' => 'ntpd', 'CentOS' => 'ntpd', 'Scientific' => 'ntpd', :default => 'ntp'),
        :ensure => enabled ? :running : :stopped, :enable => enabled, :require => package('ntp'), :pattern => 'ntpd'
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
      when 'RedHat', 'CentOS', 'Scientific'
        package 'mysql-devel', :ensure => :installed
      when 'Fedora'
        package 'mysql-libs',  :ensure => :installed
        package 'mysql-devel', :ensure => :installed
      when 'Darwin'
        # Do nothing
      else
        # Do nothing
      end
    end

    def mysql_gem
      case Facter.operatingsystem
      when 'RedHat', 'CentOS', 'Scientific'
        package 'mysql-gem', :name => 'mysql', :provider => :gem, :ensure => :installed,
          :require => [ package('mysql-devel') ]
      when 'Fedora'
        package 'mysql-gem', :name => 'mysql', :provider => :gem, :ensure => :installed,
          :require => [ package('mysql-devel'), package('mysql-libs') ]
      when 'Darwin'
        # Do nothing
      else
        # Do nothing
      end
    end

    def httpd_development_libraries
      package 'httpd-devel', :ensure => :installed
      package 'apr-devel',   :ensure => :installed
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
      when 'RedHat', 'CentOS', 'Scientific'
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
