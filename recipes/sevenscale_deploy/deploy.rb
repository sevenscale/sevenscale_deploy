namespace :deploy do
  desc <<-DESC
    Prepares one or more servers for deployment. Before you can use any \
    of the Capistrano deployment tasks with your project, you will need to \
    make sure all of your servers have been prepared with `cap deploy:setup'. When \
    you add a new server to your cluster, you can easily run the setup task \
    on just that server by specifying the HOSTS environment variable:

      $ cap HOSTS=new.server.com deploy:setup

    It is safe to run this task on servers that have already been set up; it \
    will not destroy any deployed revisions or data.
  DESC
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    
    commands = "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')} && #{try_sudo} chown -R #{fetch(:user)}.#{fetch(:user)} #{dirs.join(' ')}"
    
    users.brute_force_authenticate.each do |(user, password), servers|
      begin
        old_user, old_password = fetch(:user), fetch(:password)

        set(:user, user)
        set(:password, password)

        hosts = servers.map { |s| s.host }

        with_env('HOSTFILTER', hosts.join(',')) do
          run commands
        end
      ensure
        set(:user, old_user)
        set(:password, old_password)
      end
    end
  end
end