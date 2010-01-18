depend :remote, :command, 'tail'

namespace :logs do
  desc "tail log files"
  task :tail do
    run "tail -f #{shared_path}/log/#{rails_env}.log" do |ch, stream, out|
      print out
    end
  end
end
