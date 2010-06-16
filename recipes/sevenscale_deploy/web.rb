namespace :web do
  task :disable, :roles => :app, :except => { :no_release => true } do
    require 'erb'
    on_rollback { run "rm #{shared_path}/system/maintenance.html" }

    reason = ENV['REASON']
    deadline = ENV['UNTIL']

    template = File.read(File.join(File.dirname(__FILE__), "assets", "maintenance.rhtml"))
    result = ERB.new(template).result(binding)

    put result, "#{current_path}/public/system/maintenance.html", :mode => 0644
  end
  
end