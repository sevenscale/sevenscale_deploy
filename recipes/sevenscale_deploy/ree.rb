Capistrano::Configuration.instance(:must_exist).load do
  namespace :ree do
    # Make sure the required RPMs are installed
    # rpmist.all %w(openssl-devel readline-devel)

    desc "Install Ruby Enterprise Edition"
    task :install do
      url = 'http://rubyforge.org/frs/download.php/58677/ruby-enterprise-1.8.6-20090610.tar.gz'

      filename = File.basename(url)
      expanded_directory = filename[/^(.+)\.tar/, 1]

      # Remove ruby RPM
      sudo "yum erase -y ruby || true"

      run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
      run "curl -L -s -S -o #{shared_path}/opt/dist/#{filename} #{url}"
      run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
      run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
      run "cd #{shared_path}/opt/src/#{expanded_directory} && #{sudo} ./installer -a /usr --dont-install-useful-gems"
    end
  end
end
