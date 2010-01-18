Dir[File.dirname(__FILE__) + '/sevenscale_deploy/**/*.rb'].each do |file|
  load File.expand_path(file)
end

Dir[File.dirname(__FILE__) + '/{plugins,ext}/**/*.rb'].each do |file|
  require File.expand_path(file)
end

default_run_options[:pty] = true if respond_to?(:default_run_options)
set :keep_releases, 3
set :runner, defer { user }
