namespace :beanstalk do
  desc 'Install beanstalk server'
  task :install, :roles => :beanstalkd do
    url = 'http://xph.us/software/beanstalkd/rel/beanstalkd-1.0.tar.gz'
    filename = 'beanstalkd-1.0.tar.gz'
    expanded_directory = 'beanstalkd-1.0'

    run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
    run "curl -o #{shared_path}/opt/dist/#{filename} #{url}"
    run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
    run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
    run "cd #{shared_path}/opt/src/#{expanded_directory} && make && cp beanstalkd #{shared_path}/opt/bin/"
  end
end
