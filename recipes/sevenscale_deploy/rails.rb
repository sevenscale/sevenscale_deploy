namespace :rails do
  after 'deploy:finalize_update', 'rails:mark_rails_env'

  desc "Install Rails gems with gems:install"
  task :install_gems do
    rails_env = fetch(:rails_env, "production")

    run "cd #{latest_release} && #{try_sudo} rake RAILS_ENV=#{rails_env} gems:install"
  end

  task :mark_rails_env, :except => { :no_release => true } do
    run "echo #{rails_env} > #{latest_release}/RAILS_ENV"
  end
end
