namespace :shared do
  task :symlink do
    shared_files       = Array(fetch(:shared_files, []))
    shared_directories = Array(fetch(:shared_directories, []))
    cmd                = []
    
    cmd << "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # Remove all the old files and directories
    cmd << "rm -rf " + (shared_files + shared_directories).collect { |f| File.join(latest_release, f) }.join(' ')

    # Create any directories we need to
    cmd << "mkdir -p " + shared_files.collect do |f|
      [ File.join(shared_path, File.dirname(f)), File.join(latest_release, File.dirname(f))]
    end.join(' ')
    
    # Create any destination directories we need to
    cmd << "mkdir -p " + shared_directories.collect do |d|
      File.join(shared_path, d)
    end.join(' ')

    # Create any parent directories of directories we need to
    cmd << "mkdir -p " + shared_directories.reject do |d|
      File.dirname(d) == '.'
    end.collect do |d|
      File.join(latest_release, File.dirname(d))
    end.join(' ')

    # Symlink that stuff up
    (shared_files + shared_directories).each do |f|
      cmd << "ln -s #{shared_path}/#{f} #{latest_release}/#{f}"
    end

    run cmd.join(' && ')
  end
end