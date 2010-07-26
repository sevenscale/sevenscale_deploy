namespace :github do
  namespace :pending do
    desc 'Display pending changes ready to be deployed in a browser'
    task :default do
      branch = fetch(:branch, 'master')
      if repo = repository[/github.com:(.*)\.git$/, 1]
        system 'open', "http://github.com/#{repo}/compare/#{current_revision[0..8]}...#{branch}"
      else
        raise "The current repository '#{repository}' is not hosted on github"
      end
    end
    
    desc 'Display pending changes in master in a browser'
    task :master do
      if repo = repository[/github.com:(.*)\.git$/, 1]
        system 'open', "http://github.com/#{repo}/compare/#{current_revision[0..8]}...master"
      else
        raise "The current repository '#{repository}' is not hosted on github"
      end
    end
  end
end