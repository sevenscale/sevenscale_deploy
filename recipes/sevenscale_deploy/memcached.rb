namespace :memcached do   
  desc 'Install beanstalk server'
  task :install, :roles => :app, :only => { :memcached => true } do
    url = 'http://www.danga.com/memcached/dist/memcached-1.2.6.tar.gz'
    filename = 'memcached-1.2.6.tar.gz'
    expanded_directory = 'memcached-1.2.6'

    run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
    run "curl -o #{shared_path}/opt/dist/#{filename} #{url}"
    run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
    run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
    run "cd #{shared_path}/opt/src/#{expanded_directory} && ./configure --prefix=#{shared_path}/opt && make && make install"
  end
end
