namespace :assets do
  set(:asset_timestamp) { run_locally(source.local.scm(:log, '-1', '--pretty=format:%cd', '--date=raw', real_revision, '--', 'public/'))[/^(\d+)/, 1] }

  desc 'Mark asset timestamp'
  task :mark, :roles => :app, :except => { :no_release => true } do
    run "echo #{asset_timestamp} > #{release_path}/ASSET_TIMESTAMP"
  end
end