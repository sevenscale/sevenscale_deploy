namespace :dir do
  desc "Setup directories"
  task :permissions do
    deploy_user = fetch(:user)

    sudo "/bin/chown -R '#{deploy_user}.#{deploy_user}' '#{deploy_to}' '#{releases_path}'"
  end
  
  desc "Setup selinux"
  task :selinux do
    sudo "/sbin/restorecon -R '#{deploy_to}'"
  end
end
