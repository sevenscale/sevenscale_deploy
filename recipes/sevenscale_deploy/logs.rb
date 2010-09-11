depend :remote, :command, 'tail'

namespace :logs do
  desc "tail log files"
  task :tail do
    log_filename = fetch(:log_filename, "#{rails_env}.log")

    begin
      run "tail -f #{shared_path}/log/#{log_filename}" do |ch, stream, out|
        print out
      end
    rescue Interrupt
      exit(0)
    end
  end
end
