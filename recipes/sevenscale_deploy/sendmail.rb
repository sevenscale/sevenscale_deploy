Capistrano::Configuration.instance(:must_exist).load do
  namespace :sendmail do
    desc "Enable sendmail on boot and start"
    task :enable, :only => { :sendmail => true } do
      sudo "/sbin/chkconfig sendmail on"
      sudo "/etc/rc.d/init.d/sendmail start"
    end

    desc "Restart sendmail"
    task :restart, :only => { :sendmail => true } do
      sudo "/etc/rc.d/init.d/sendmail restart"
    end
  end
end