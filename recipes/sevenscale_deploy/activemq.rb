namespace :activemq do   
  desc 'Install beanstalk server'
  task :install, :roles => :activemq do
    filename = 'apache-activemq-5.2.0-bin.tar.gz'
    url = "http://download.nextag.com/apache/activemq/apache-activemq/5.2.0/#{filename}"
    expanded_directory = 'apache-activemq-5.2.0'

    run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
    run "curl -o #{shared_path}/opt/dist/#{filename} #{url}"
    run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
    run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
    run "rm -rf #{shared_path}/opt/activemq && cp -R #{shared_path}/opt/src/#{expanded_directory} #{shared_path}/opt/activemq"
  end
end
