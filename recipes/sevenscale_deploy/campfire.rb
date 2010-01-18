# Lifted from:
# http://github.com/vigetlabs/viget_deployment/tree/master/recipes/campfire.rb
begin
  require 'uri'
  require 'tinder'

  namespace :campfire do
    after "deploy", "campfire:notify"
    after "deploy:migrations", "campfire:notify"
    after "deploy:rollback", "campfire:notify"
    
    desc '[internal] Announces deployments in one or more Campfire rooms.'
    task :notify do
      campfires = fetch(:campfires,nil)
      notify    = fetch(:campfire_notify,nil)
      unless campfires.nil? || notify.nil?
        notify.each do |name|
          config = campfires[name]
          campfire = Tinder::Campfire.new(config[:domain], :ssl => config[:ssl])
          if campfire.login(config[:email], config[:password])
            if room = campfire.find_room_by_name(config[:room])
              logger.debug "sending message to #{config[:room]} on #{name.to_s} Campfire"

              message = "[CAP] %s just deployed revision %s of %s" % [
                ENV['USER'], current_revision.to_s[0..5], fetch(:application), 
              ]
              if stage = fetch(:rails_env, nil)
                message << " to #{stage}"
              end
              room.speak "#{message}."
              changes = `#{source.local.log(previous_revision, current_revision)}`.chomp
              room.paste changes unless changes.blank?
            else
              logger.debug "Campfire #{name.to_s} room #{config[:room]} not found"
            end
          else
            logger.debug "Campfire #{name.to_s} email and/or password incorrect"
          end
        end
      end
    end
  end
rescue LoadError
  nil # skip campfire stuff if tinder can't be required
end
