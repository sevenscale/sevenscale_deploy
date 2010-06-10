namespace :moonshine do
  # after 'deploy:finalize_update' do
  #   apply if fetch(:moonshine_apply, true)
  # end

  desc 'Setup moonshine'
  task :setup do
    install_required_gems
    install_git
    setup_directories
  end

  desc 'Install required gems'
  task :install_required_gems do
    sudo 'gem install rake shadow_puppet --no-rdoc --no-ri'
  end

  desc <<-DESC
  Applies the lib/moonshine_setup_manifest.rb manifest, which replicates the old
  capistrano deploy:setup behavior.
  DESC
  task :setup_directories do
    moonshine_yml_path            = fetch(:moonshine_yml_path, File.join(ENV['RAILS_ROOT'] || Dir.pwd, 'config', 'moonshine.yml'))
    moonshine_setup_manifest_path = fetch(:moonshine_setup_manifest, File.expand_path('../../../../moonshine/lib/moonshine_setup_manifest.rb', __FILE__))

    upload moonshine_yml_path.to_s,       '/tmp/moonshine.yml'
    upload moonshine_setup_manifest_path, '/tmp/moonshine_setup_manifest.rb'

    sudo 'shadow_puppet /tmp/moonshine_setup_manifest.rb; rm /tmp/moonshine_setup_manifest.rb /tmp/moonshine.yml'
  end

  desc 'Apply the Moonshine manifest for this application'
  task :apply, :except => { :no_release => true } do
    moonshine_manifest = fetch(:moonshine_manifest, 'application_manifest')

    sudo "env RAILS_ROOT=#{latest_release} RAILS_ENV=#{fetch(:rails_env)} CAPISTRANO_ROLES=$CAPISTRANO:ROLES$ shadow_puppet #{latest_release}/app/manifests/#{moonshine_manifest}.rb"
  end

  desc 'Install git'
  task :install_git do
    install_git_package
  end

  def fetch_os_distribution
    fetch :os_distribution, lambda {
      capture("/usr/bin/lsb_release -a")[/Distributor ID:\s+(.*)$/, 1].chomp
    }
  end

  def install_git_package
    case distribution = fetch_os_distribution
    when 'Fedora'
      sudo 'yum install -y git-core'
    when 'Ubuntu'
      sudo 'apt-get install -q -y git-core'
    else
      raise "Unknown distribution: #{distribution.inspect}"
    end
  end
end