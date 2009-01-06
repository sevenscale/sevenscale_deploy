require 'capistrano/recipes/deploy/scm/subversion' 

# use switch instead of update to sync the subversion repository (so that it handles a possible repository change) 
Capistrano::Deploy::SCM::Subversion.class_eval do 
  def sync(revision, destination) 
    scm :switch, verbose, authentication, "-r#{revision}", repository, destination 
  end 
end