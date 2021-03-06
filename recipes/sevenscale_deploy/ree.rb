require 'set'

namespace :ree do
  desc "Install Kiji"
  task :install_kiji do
    url = "https://download.github.com/twitter-rubyenterpriseedition187-248-kiji_0_11-0-g5ac7c4f.tar.gz"
    version_matcher = /kiji.*0.11/

    ree.install_ruby(url, version_matcher)
  end

  desc "Install Ruby Enterprise Edition"
  task :install do
    url             = 'http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2011.03.tar.gz'
    version_matcher = /1.8.7.*2011.03/

    ree.install_ruby_from_bootstrap(version_matcher)
  end

  def install_ruby_from_bootstrap(version_matcher, options = {})
    hosts_in_need = ree.find_hosts_in_need('ruby -v') { |out| out.match(version_matcher) && !fetch(:force_ree_install, false) }

    unless hosts_in_need.empty?
      users.connect_as(fetch(:shadow_puppet_user, fetch(:user)), fetch(:shadow_puppet_password, fetch(:password))) do
        upload File.expand_path('../assets/ruby-bootstrap.sh', __FILE__), '/tmp/ruby-bootstrap.sh', :hosts => hosts_in_need
        run "#{sudo} bash /tmp/ruby-bootstrap.sh && rm -f /tmp/ruby-bootstrap.sh", :hosts => hosts_in_need
      end
    end
  end

  # There's a major assumption here that all systems are of the same Linux Distribution
  def install_ruby(url, version_matcher, options = {})
    filename           = File.basename(url)
    expanded_directory = filename[/^(.+)\.tar/, 1]

    cmds = []

    # Remove ruby package and install required packages
    cmds << command_for_packages

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
    cmds << "cd #{src_root}/#{expanded_directory} && #{sudo} ./installer -a /usr --dont-install-useful-gems && #{sudo} rm -rf #{src_root}"

    hosts_in_need = ree.find_hosts_in_need('ruby -v') { |out| out.match(version_matcher) && !fetch(:force_ree_install, false) }

    unless hosts_in_need.empty?
      users.connect_as(fetch(:shadow_puppet_user, fetch(:user)), fetch(:shadow_puppet_password, fetch(:password))) do
        run cmds.join(' && '), :hosts => hosts_in_need
      end
    end
  end

  def fetch_os_distribution
    fetch(:os_distribution) { capture("/usr/bin/lsb_release -a")[/Distributor ID:\s+(.*)$/, 1].chomp }
  end

  def command_for_packages
    case distribution = fetch_os_distribution
    when 'Fedora'
      %{#{sudo} /bin/sh -c "yum erase -qy ruby ; yum install -qy curl gcc make bzip2 tar which patch gcc-c++ zlib-devel openssl-devel readline-devel"}
    when 'RedHat'
      %{#{sudo} /bin/sh -c "yum erase -qy ruby ruby-libs; yum install -qy curl gcc make bzip2 tar which patch gcc-c++ zlib-devel openssl-devel readline-devel"}
    when 'Ubuntu'
      %{#{sudo} /bin/sh -c "apt-get remove -q -y '^.*ruby.*' ; apt-get install -q -y build-essential patch zlib1g-dev libssl-dev libreadline5-dev"}
    else
      raise "Unknown distribution: #{distribution.inspect}"
    end
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
