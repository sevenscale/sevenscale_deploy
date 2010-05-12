# Originally lifted from:
# http://github.com/vigetlabs/viget_deployment/tree/master/recipes/campfire.rb
#
# Usage:
#
#    campfire.register 'sevenscale', 'b8d9b31...', :room => 'crazypants', :ssl => true
#
namespace :campfire do
  set(:previous_current_revision) { raise "Previous current revision was never fetched" }
  
  before 'deploy:symlink',           'campfire:save_previous_current_revision'
  before 'deploy:rollback:revision', 'campfire:save_previous_current_revision'
  
  def register(domain, token, config = {})
    begin
      require 'uri'
      require 'tinder'
    rescue LoadError
      return false # skip campfire stuff if tinder can't be required
    end

    short_domain = domain[/^([^\.]+)/, 1]

    namespace short_domain do
      after 'deploy',            "campfire:#{short_domain}:notify"
      after 'deploy:migrations', "campfire:#{short_domain}:notify"
      after 'deploy:rollback',   "campfire:#{short_domain}:notify"

      desc "Notify #{short_domain} of deploy"
      task :notify do
        campfire = Tinder::Campfire.new(domain, :ssl => config[:ssl])
        campfire.login(token, 'x')
        room = campfire.find_room_by_name(config[:room]) rescue nil
        
        if room
          logger.debug "sending message to #{config[:room]} on #{short_domain} Campfire"

          message = "[CAP] %s just deployed revision %s of %s" % [
            ENV['USER'], current_revision.to_s[0..5], fetch(:application), 
          ]
          if stage = fetch(:rails_env, nil)
            message << " to #{stage}"
          end
          room.speak "#{message}."
          changes = `#{source.local.log(previous_current_revision, current_revision)}`.chomp
          room.paste changes unless changes.blank?
        else
          logger.debug "Campfire #{short_domain} room '#{config[:room]}' not found"
        end
      end
    end
  end
  
  task :save_previous_current_revision do
    set(:previous_current_revision, capture("cat #{current_path}/REVISION").chomp)
  end
end