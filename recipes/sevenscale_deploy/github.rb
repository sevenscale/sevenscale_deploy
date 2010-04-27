namespace :github do
  namespace :pending do
    desc 'Display pending changes ready to be deployed in a browser'
    task :default do
      if m = repository.match(/github.com:(.*)\.git$/)
        system 'open', "http://github.com/#{m[1]}/compare/#{current_revision[0..8]}...#{branch}"
      else
        raise "The current repository '#{repository}' is not hosted on github"
      end
    end
    
    desc 'Display pending changes in master in a browser'
    task :master do
      if m = repository.match(/github.com:(.*)\.git$/)
        system 'open', "http://github.com/#{m[1]}/compare/#{current_revision[0..8]}...master"
      else
        raise "The current repository '#{repository}' is not hosted on github"
      end
    end
  end
end