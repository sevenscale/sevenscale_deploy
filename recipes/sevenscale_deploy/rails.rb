Capistrano::Configuration.instance(:must_exist).load do
  namespace :rails do
    desc "Install Rails gems with gems:install"
    task :install_gems do
      rails_env = fetch(:rails_env, "production")

      run "cd #{latest_release} && #{try_sudo} rake RAILS_ENV=#{rails_env} gems:install"
    end
  end
end