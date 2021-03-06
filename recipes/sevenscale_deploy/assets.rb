namespace :assets do
  set(:asset_timestamp_directories, %w(public))
  set(:asset_timestamp) { run_locally(source.local.scm(:log, '-1', '--pretty=format:%cd', '--date=raw', real_revision, '--', *Array(asset_timestamp_directories).flatten))[/^(\d+)/, 1] }

  desc 'Mark asset timestamp'
  task :mark, :roles => :web, :except => { :no_release => true } do
    run "echo #{asset_timestamp} > #{release_path}/ASSET_TIMESTAMP"
  end
end