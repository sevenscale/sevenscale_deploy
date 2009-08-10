Capistrano::Configuration.instance(:must_exist).load do
  namespace :user do
    @@users = []
    
    namespace :create do
      desc 'Create all users'
      task :default do
        tasks.keys.each do |key|
          send(key) unless key == DEFAULT_TASK
        end
      end
    end

    def activate(user, options = {})
      namespace :create do
        desc "Create user #{user}#{' with all user keys' if options[:all_keys]}"
        task user do
          create_user(user, options)
        end
      end
    end
  
    def create_user(user, options = {})
      command = "grep -q '^#{user}:' || #{try_sudo} /usr/sbin/useradd '#{user}'"
      args = []

      if options[:groups]
        command << " -G #{Array(options[:groups]).join(',')}"
      end

      run command

      update_authorized_keys2(user, options[:all_keys])
    end
    
    def update_authorized_keys2(user, all_keys = false)
      key_files = all_keys ? Dir["ssh_keys/*/*"] : Dir["ssh_keys/#{user}/*"]
      user_keys = key_files.collect { |file| File.read(file).split(/(\r?\n)+/) }.flatten
    
      authorized_keys = capture("cat ~#{user}/.ssh/authorized_keys2").split(/\r?\n/)
    
      authorized_keys += user_keys.reject { |line| authorized_keys.include?(line) }
    
      run("mkdir -p -m 700 ~#{user}/.ssh")
      put authorized_keys.join("\n"), "~#{user}/.ssh/authorized_keys2", :mode => 0600
      run("chown -R #{user}.#{user} ~#{user}/.ssh")
    end
  end
  
  def run_as_root
    normal_user = fetch(:user)

    if normal_user != 'root'
      normal_password = fetch(:password)

      if fetch(:root_needs_password, true)
        logger.info "Command must run as root. Please specify root password."
        set(:user, 'root')
        set(:password, Capistrano::CLI.password_prompt)
      end
    end
  
    yield
  ensure
    if normal_user != 'root'
      set(:user, normal_user)
      set(:password, normal_password)
    end
  end
end