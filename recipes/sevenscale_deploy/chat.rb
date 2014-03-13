# Usage:
#
#   slack.register 'sevenscale', 'b8d9b31...', :channel  => 'Ops'
#                                              :username => 'Robot'
#                                              :emoji    => ':godmode:'
#
# Options:
#
# All are optional. Defaults are configured in the incoming Slack webhook.
#
#   channel: Name of the channel to notify.
#   username: The name as shown in the message.
#   emoji: The avatar as shown in the message.
#
namespace :slack do
  set(:previous_current_revision) { raise "Previous current revision was never fetched" }
  task :save_previous_current_revision do
    set(:previous_current_revision, (capture("cat #{current_path}/REVISION").chomp rescue nil))
  end

  def escape_html_entities(message)
    message.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def register_slack(domain, &speak)
    namespace domain do
      before 'deploy',            "slack:#{domain}:notify_start"
      before 'deploy:migrations', "slack:#{domain}:notify_start"
      after  'deploy',            "slack:#{domain}:notify_finished"
      after  'deploy:migrations', "slack:#{domain}:notify_finished"

      task :notify_start do
        deployer    = ENV['USER']
        deployed    = current_revision.to_s[0..7]
        deploying   = real_revision.to_s[0..7]
        github_repo = repository[/github.com:(.*)\.git$/, 1]
        compare_url = "http://github.com/#{github_repo}/compare/#{deployed}...#{deploying}"

        message = "%s is deploying (%s..%s) of %s" % [
          ENV['USER'], deployed, deploying, fetch(:application),
        ]
        if rails_env = fetch(:rails_env, nil)
          message << " to #{stage}"
        end
        message << " with `cap #{ARGV.join(' ')}` (#{compare_url})"

        speak.call message, :start

        # Make sure we say something if there's an error
        at_exit do
          if ex = $!
            message = "%s's deploy of %s" % [
              ENV['USER'], fetch(:application),
            ]
            if rails_env = fetch(:rails_env, nil)
              message << " to #{rails_env}"
            end

            if ::Interrupt === ex
              message << " was canceled."
            else
              message << " failed with exception #{ex.class}: "
              if ex.message.to_s.length > 200
                message << ex.message.to_s[0..200] << "..."
              else
                message << ex.message.to_s
              end
            end

            speak.call message, :error
          end
        end
      end

      task :notify_finished do
        message = "%s's deploy of %s" % [
          ENV['USER'], fetch(:application)
        ]
        if rails_env = fetch(:rails_env, nil)
          message << " to #{rails_env}"
        end
        message << " is done."

        speak.call message, :finished
      end
    end
  end

  def register(domain, token, config = {})
    require 'net/http'

    default_payload = {}
    default_payload['channel']    = config[:channel]  if config[:channel]
    default_payload['username']   = config[:username] if config[:username]
    default_payload['icon_emoji'] = config[:emoji]    if config[:emoji]

    register_slack domain do |message, status|
      status_color = case status
                     when :error then 'danger'
                     when :finished then 'good'
                     else ''
                     end

      payload = default_payload.merge('attachments' => [
        { 'text'  => escape_html_entities(message),
          'color' => status_color }])

      uri = URI.parse("https://#{domain}.slack.com/services/hooks/incoming-webhook?token=#{token}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.use_ssl = true
      store = OpenSSL::X509::Store.new
      store.set_default_paths
      http.cert_store = store
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(:payload => payload.to_json)
      http.request request
    end
  end
end
