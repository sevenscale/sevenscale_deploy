module Rpmist
  @@rpms = Hash.new { |h,role| h[role] = {} }

  # Usage:
  #   role(:app, %w(hpricot mongrel))
  def role(roles, *rpms)
    options = {}
    
    Array(roles).each do |role|
      rpms.flatten.each do |rpm|
        @@rpms[role] = options
      end
    
      namespace :rpms do
        desc "Install all required RPMs"
        task :install do
          @@rpms.keys.each do |role|
            send(role).send(:install)
          end
        end

        task_opts = {}
        unless role == :all
          task_opts = { :roles => role }
        end
      
        namespace role do
          desc "Install required RPMs"
          task :install, task_opts do
            rpmist.install_rpms(@@rpms[role].keys)
          end
        end
      end
    end
  end
  
  def all(*rpms)
    self.role(:all, *rpms)
  end
  
  def install_rpms(*rpms)
    rpm_list = rpms.flatten.join(' ')

    sudo "yum install -qy #{rpm_list}", :pty => true
  end
end

Capistrano.plugin :rpmist, Rpmist

