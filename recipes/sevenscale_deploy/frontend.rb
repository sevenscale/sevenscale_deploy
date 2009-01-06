module Frontend
  def select(mechanism)
    namespace :deploy do
      desc "[#{mechanism}] Start Application"
      task :start, :roles => :app do
        send(mechanism).start
      end

      desc "[#{mechanism}] Stop Application"
      task :stop, :roles => :app do
        send(mechanism).stop
      end
      
      desc "[#{mechanism}] Restart Application"
      task :restart, :roles => :app do
        send(mechanism).restart
      end
      
      
    end
  end
end

Capistrano.plugin :frontend, Frontend