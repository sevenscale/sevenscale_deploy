Capistrano::Configuration.instance(:must_exist).load do
  namespace :sphinx do
    desc 'Install beanstalk server'
    task :install, :roles => :sphinx do
      url = 'http://sphinxsearch.com/downloads/sphinx-0.9.8.1.tar.gz'
      filename = 'sphinx-0.9.8.1.tar.gz'
      expanded_directory = 'sphinx-0.9.8.1'

      run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
      run "curl -o #{shared_path}/opt/dist/#{filename} #{url}"
      run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
      run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
      run "cd #{shared_path}/opt/src/#{expanded_directory} && ./configure --prefix=#{shared_path}/opt && make && make install"
    end

    desc 'Index the sphinx datastore'
    task :index, :roles => :sphinx do
      rails_env = fetch(:rails_env, "production")

      run "cd #{latest_release} && rake RAILS_ENV=#{rails_env} thinking_sphinx:index"
    end

    desc 'Update sphinx config'
    task :configure, :roles => :sphinx do
      rails_env = fetch(:rails_env, "production")

      run "cd #{latest_release} && rake RAILS_ENV=#{rails_env} thinking_sphinx:configure"
    end
  end
end
