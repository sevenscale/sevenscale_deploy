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

  desc 'Upload shared files'
  task :upload, :except => { :no_release => true } do
    files = (ENV["FILES"] || "").split(",").map { |f| Dir[f.strip] }.flatten
    abort "Please specify at least one file or directory to update (via the FILES environment variable)" if files.empty?

    files.each { |file| top.upload(file, File.join(shared_path, file)) }
  end

  def upload_file(filename, contents)
    @shared_files_to_upload ||= []
    @shared_files_to_upload << [ filename, contents ]

    desc 'Upload generated files to shared directory'
    task :upload_files, :except => { :no_release => true } do
      @shared_files_to_upload.each do |(filename, contents)|
        put contents, filename, :mode => 0664
      end
    end

    after "deploy:update_code", 'shared:upload_files'
  end
end