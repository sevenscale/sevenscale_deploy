namespace :moonshine do
  # after 'deploy:finalize_update' do
  #   apply if fetch(:moonshine_apply, true)
  # end
  before 'moonshine:apply', 'moonshine:ensure_installed'

  desc 'Setup moonshine'
  task :setup do
    ensure_installed
    setup_directories
  end

  desc 'Install required gems'
  task :ensure_installed do
    commands = [
      "system(*%w(gem install activesupport -v 2.3.5 --no-rdoc --no-ri)) unless Gem.available?(%(activesupport))",
      "system(*%w(gem install shadow_puppet --no-rdoc --no-ri)) unless Gem.available?(%(shadow_puppet))",
      "system(*%w(gem install rake -v 0.8.7 --no-rdoc --no-ri)) unless Gem.available?(%(rake))"
      ]

    users.connect_as(fetch(:shadow_puppet_user, fetch(:user)), fetch(:shadow_puppet_password, fetch(:password))) do
      sudo(%(/bin/sh -c "ruby -rubygems -e '#{commands.join("; ")}'"), :shell => false)
    end
  end

  desc <<-DESC
  Applies the lib/moonshine_setup_manifest.rb manifest, which replicates the old
  capistrano deploy:setup behavior.
  DESC
  task :setup_directories do
    moonshine_yml_path            = fetch(:moonshine_yml_path, File.join(ENV['RAILS_ROOT'] || Dir.pwd, 'config', 'moonshine.yml'))
    moonshine_setup_manifest_path = fetch(:moonshine_setup_manifest, File.expand_path('../../../../moonshine/lib/moonshine_setup_manifest.rb', __FILE__))

    upload moonshine_yml_path.to_s,       '/tmp/moonshine.yml'
    upload moonshine_setup_manifest_path, "/tmp/#{File.basename(moonshine_setup_manifest_path)}"

    users.connect_as(fetch(:shadow_puppet_user, fetch(:user)), fetch(:shadow_puppet_password, fetch(:password))) do
      sudo %{/bin/sh -c "ruby -S -rthread shadow_puppet /tmp/#{File.basename(moonshine_setup_manifest_path)}; rm -f /tmp/#{File.basename(moonshine_setup_manifest_path)} /tmp/moonshine.yml"}
    end
  end

  desc 'Apply the Moonshine manifest for this application'
  task :apply, :except => { :no_release => true } do
    moonshine_manifest = fetch(:moonshine_manifest, 'application_manifest')

    users.connect_as(fetch(:shadow_puppet_user, fetch(:user)), fetch(:shadow_puppet_password, fetch(:password))) do
      sudo "env RAILS_ROOT=#{latest_release} RAILS_ENV=#{fetch(:rails_env)} CAPISTRANO_ROLES=$CAPISTRANO:ROLES$ ruby -S -rthread shadow_puppet #{latest_release}/app/manifests/#{moonshine_manifest}.rb"
    end
  end
end
