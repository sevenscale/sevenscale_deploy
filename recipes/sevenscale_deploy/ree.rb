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

    src_root = "/tmp/cap-ree-#{$$}"

    # Create the directories we need
    cmds << "mkdir -p #{src_root}"

    # Cleanup if we've done another run before
    cmds << "#{sudo} rm -rf #{src_root}/#{expanded_directory} #{src_root}/#{filename}"

    # Download the file
    cmds << "curl -L -s -S -o #{src_root}/#{filename} #{url}"

    # Extract the data
    cmds << "tar zxvf #{src_root}/#{filename} -C #{src_root}"

    # Run the installer
    cmds << "cd #{src_root}/#{expanded_directory} && #{sudo} ./installer -a /usr --dont-install-useful-gems && rm -rf #{src_root}"

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
