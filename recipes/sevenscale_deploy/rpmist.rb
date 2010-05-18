require 'set'

namespace :rpms do
  @@rpms = Hash.new { |h,role| h[role] = Set.new }

  namespace :install do
    desc 'Install required RPMs for all roles'
    task :default do
      parallel do |session|
        rpms.real_roles.each do |role|
          session.when "in?(:#{role.to_s})", yum_command_for(role)
        end
        session.else yum_command_for(:all)
      end
    end
  end

  def all(*rpms)
    @@rpms[:all].merge(rpms.flatten)
  end

  def role(roles, *rpms)
    Array(roles).each do |role|
      role = role.to_sym

      @@rpms[role].merge(rpms.flatten)

      if role != :all
        namespace :install do
          desc "Install required RPMs for #{role}"
          task role, :roles => role do
            run yum_command_for(role)
          end
        end
      end
    end
  end

  def real_roles
    @@rpms.keys - [ :all ]
  end

  def yum_command_for(role)
    "#{sudo} yum -qy install #{(@@rpms[role.to_sym] + @@rpms[:all]).to_a.join(' ')}"
  end
end
