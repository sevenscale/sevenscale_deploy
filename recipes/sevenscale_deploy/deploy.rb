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
    
    commands = "#{sudo} mkdir -p #{dirs.join(' ')} && #{sudo} chmod g+w #{dirs.join(' ')} && #{sudo} chown -R #{fetch(:user)}.#{fetch(:user)} #{dirs.join(' ')}"
    
    users.brute_force_authenticate.each do |(user, password), servers|
      users.connect_as(user, password) do
        hosts = servers.map { |s| s.host }

        with_env('HOSTFILTER', hosts.join(',')) do
          run commands
        end
      end
    end
  end
end