namespace :memcached do   
  desc 'Install beanstalk server'
  task :install, :roles => :app, :only => { :memcached => true } do
    url = 'http://memcached.googlecode.com/files/memcached-1.4.5.tar.gz'

    filename           = File.basename(url)
    expanded_directory = filename[/^(.+)\.tar/, 1]

    run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
    run "curl -o #{shared_path}/opt/dist/#{filename} #{url}"
    run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
    run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
    run "cd #{shared_path}/opt/src/#{expanded_directory} && ./configure --prefix=#{shared_path}/opt && make && make install"
  end
end
