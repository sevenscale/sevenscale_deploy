depend :remote, :command, 'tail'

namespace :logs do
  desc "tail log files"
  task :tail do
    log_filename = fetch(:log_filename, "#{rails_env}.log")
    logs = Array(log_filename).collect { |l| "#{shared_path}/log/#{l}" }

    begin
      run "tail -f #{logs.join(' ')}" do |ch, stream, out|
        if ENV['WITH_HOSTNAME']
          print "  [#{ch[:host]}] " + out.chomp.gsub(/\n/, "\n  [#{ch[:host]}] ") + "\n"
        else
          print out
        end
      end
    rescue Interrupt
      exit(0)
    end
  end

  desc "grep log files"
  task :grep do
    log_filename = fetch(:log_filename, "#{rails_env}.log")
    logs = Array(log_filename).collect { |l| "#{shared_path}/log/#{l}" }

    abort "Must provide PATTERN=" unless ENV['PATTERN']

    command = "grep "

    if ENV['CONTEXT']
      command << %{-C "#{ENV['CONTEXT']}"}
    end

    run %{#{command} -e "#{ENV['PATTERN']}" #{logs.join(' ')}}
  end
end
