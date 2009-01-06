Dir[File.dirname(__FILE__) + '/sevenscale_deploy/**/*.rb'].each do |file|
  load File.expand_path(file)
end

Capistrano::Configuration.instance(:must_exist).load do
  default_run_options[:pty] = true if respond_to?(:default_run_options)
  set :keep_releases, 3
  set :runner, defer { user }
end
