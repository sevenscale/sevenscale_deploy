namespace :ree do
  # Make sure the required RPMs are installed
  # rpmist.all %w(openssl-devel readline-devel)

  desc "Install Ruby Enterprise Edition"
  task :install do
    url             = 'http://rubyforge.org/frs/download.php/68719/ruby-enterprise-1.8.7-2010.01.tar.gz'
    version_matcher = /1.8.7.*2010.01/

    ree.install_ruby(url, version_matcher)
  end

  def install_ruby(url, version_matcher, options = {})
    filename           = File.basename(url)
    expanded_directory = filename[/^(.+)\.tar/, 1]

    cmds = []

    unless options[:yum] == false
      # Remove ruby RPM and install required RPMs
      cmds << %{#{sudo} /bin/sh -c "yum erase -y ruby ; yum install -y curl gcc make bzip2 tar which patch gcc-c++ zlib-devel openssl-devel readline-devel"}
    end

    # Create the directories we need
    cmds << "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"

    # Download the file
    cmds << "curl -L -s -S -o #{shared_path}/opt/dist/#{filename} #{url}"

    # Cleanup if we've done another run before
    cmds << "#{sudo} rm -rf #{shared_path}/opt/src/#{expanded_directory}"

    # Extract the data
    cmds << "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"

    # Run the installer
    cmds << "cd #{shared_path}/opt/src/#{expanded_directory} && #{sudo} ./installer -a /usr --dont-install-useful-gems"

    hosts_in_need = ree.find_hosts_in_need('ruby -v') { |out| out.match(version_matcher) }

    run cmds.join(' && '), :hosts => hosts_in_need
  end

  def find_hosts_in_need(command, &block)
    all_servers    = Set.new
    passed_servers = Set.new

    begin
      invoke_command(command) do |ch,stream,out|
        all_servers << ch[:server]

        if block.call(out)
          passed_servers << ch[:server]
        end
      end
    rescue Capistrano::CommandError
    end


    all_servers - passed_servers
  end
end
