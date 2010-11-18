# Papertrail plugin to setup remote syslog from flat file logs
#
# Author: Troy Davis <troy@sevenscale.com>
# Author: Eric Lindvall <eric@sevenscale.com>
#
# Usage:
#
# # Set a default log destination and files for all roles
# papertrail.role :all, :host => 'logs.papertrailapp.com', :port => 514
# papertrail.role :all, %w(/var/log/yum.log)

# # On app servers, collect from 2 more files
# papertrail.role :app, %w(/var/log/httpd/error_log /var/log/redis.log)
#
# # On DB servers, collect from 1 more file, and send to otherhost.com:23456 instead
# papertrail.role :db, '/var/log/mysqld.log'
# papertrail.role :db, :host => 'otherhost.com', :port => 23456
# 
# Note: only the most specific single host & port (for :all or a given role) will be used. Files
# are additive between :all and a specific role.

namespace :papertrail do
  after 'deploy:finalize_update', 'papertrail:write_config_file'
  after 'deploy:finalize_update', 'papertrail:restart'
  
  def files
    @@files ||= Hash.new { |h,role| h[role] = [] }
  end

  def destinations
    @@destinations ||= Hash.new { |h,role| h[role] = [] }
  end
  
  def active_roles
    @@files.keys.delete_if { |v| v == :all }
  end

  namespace :apply do
    desc "Write new log_files.yml"
    task :default do
      parallel do |session|
        papertrail.active_roles.each do |role|
          session.when "in?(:#{role.to_s})", write_config_file_for(role)
        end
        session.else write_config_file_for(:all)
      end
    end
  end
  
  def all(setting)
    role(:all, setting)
  end

  def role(role, setting)
    files = []
    if setting.is_a?(Array)
      papertrail.files[role.to_sym] += s
    elsif setting.is_a?(String)
      papertrail.files[role.to_sym] += [s]
    elsif setting.is_a(Hash)
      papertrail.destinations[role.to_sym] = { 
        'host' => setting['host'],
        'port' => setting['port']
      }
    end
  end

  def write_config_file_for(role)
    files = papertrail.files[:role] || []
    files += papertrail.files[:all]
    files.uniq!
    
    destination = papertrail.destinations[:role] || papertrail.destinations[:all]

    return if files.empty? || !destination

    config_hash = { 'files'       => files,
                    'destination' => destination }
                    
    run "mkdir -p #{shared_path}/config"
    put YAML::dump(config_hash), "#{shared_path}/config/log_files.yml"
    run "ln -nsf #{shared_path}/config/log_files.yml #{release_path}/config/log_files.yml"
  end
  
  desc "Restart remote_syslog"
  task :restart
    # needs work
    sudo %{killall remote_syslog && /usr/bin/remote_syslog -c #{release_path}/config/log_files.yml}
  end
end
