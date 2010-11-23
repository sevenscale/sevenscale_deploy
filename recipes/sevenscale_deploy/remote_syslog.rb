# Plugin to setup remote syslog from flat file logs
#
# Author: Troy Davis <troy@sevenscale.com>
# Author: Eric Lindvall <eric@sevenscale.com>
#
# Usage:
#
# # Set a log destination and files for all roles
# remote_sylog.destination 'logs.papertrailapp.com', 12345
# remote_sylog.role :all, %w(/var/log/yum.log)

# # On app servers, collect from 2 more files
# remote_sylog.role :app, %w(/var/log/httpd/error_log /var/log/redis.log)
#
# # On DB servers, collect from 1 more file
# remote_sylog.role :db, '/var/log/mysqld.log'
# 
# Note: destination port defaults to 514.

namespace :remote_sylog do
  after 'deploy:finalize_update', 'remote_sylog:apply'
  after 'deploy:finalize_update', 'remote_sylog:restart'
  
  desc "Write new log_files.yml"
  task :apply do
    parallel do |session|
      remote_sylog.active_roles.each do |role|
        session.when "in?(:#{role.to_s})", write_config_file_for(role)
      end
      session.else write_config_file_for(:all)
    end
  end

  desc "Restart remote_syslog"
  task :restart do
    sudo "/etc/rc.d/init.d/remote_syslog restart"
  end
  
  def files
    @@files ||= Hash.new { |h,role| h[role] = [] }
  end

  def active_roles
    @@files.keys.delete_if { |v| v == :all }
  end

  
  def all(setting)
    role(:all, setting)
  end

  def destination(host, port = 514)
    @@dest_host = host
    @@dest_port = port
  end

  def role(role, files)
    if files.is_a?(Array)
      remote_sylog.files[role.to_sym] += files
    elsif files.is_a?(String)
      remote_sylog.files[role.to_sym] += [files]
    end
  end

  def write_config_file_for(role)
    files = remote_sylog.files[role] + remote_sylog.files[:all]
    files.uniq!
    
    return if files.empty? || !@@dest_host || !@@dest_port

    config_hash = { 'files'       => files,
                    'destination' => { 'host' => @@dest_host, 'port' => @@dest_port } }
                    
    run "mkdir -p #{shared_path}/config"
    put YAML::dump(config_hash), "#{shared_path}/config/log_files.yml"
    run "ln -nsf #{shared_path}/config/log_files.yml #{release_path}/config/log_files.yml"
  end
end
