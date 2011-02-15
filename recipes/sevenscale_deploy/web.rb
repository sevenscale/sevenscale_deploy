namespace :web do
  desc 'Enable web site'
  task :enable, :roles => :app, :except => { :no_release => true } do
    run "rm #{current_path}/public/system/maintenance.html"
  end
  
  desc 'Disable web site'
  task :disable, :roles => :app, :except => { :no_release => true } do
    require 'erb'
    on_rollback { run "rm #{current}/public/system/maintenance.html" }

    reason = ENV['REASON']
    deadline = ENV['UNTIL']

    maintenance_file = fetch(:maintenance_file, File.join(File.dirname(__FILE__), "assets", "maintenance.rhtml"))

    template = File.read(maintenance_file)
    result = ERB.new(template).result(binding)

    put result, "#{current_path}/public/system/maintenance.html", :mode => 0644
  end
end