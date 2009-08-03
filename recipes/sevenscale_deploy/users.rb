module Users
  def create_user(user, options = {})
    args = []
    
    if options[:groups]
      args += [ '-G', Array(options[:groups]).join(',') ]
    end
    
    run "grep -q '^#{user}:' || /usr/sbin/useradd '#{user}' #{args.join(' ')}"

    update_authorized_keys2(user)
  end
  
  def update_authorized_keys2(user)
    user_keys = Dir["ssh_keys/#{user}/*"].collect { |file| File.read(file).split(/(\r?\n)+/) }.flatten
    
    authorized_keys = capture("cat ~#{user}/.ssh/authorized_keys2").split(/\r?\n/)
    
    authorized_keys += user_keys.reject { |line| authorized_keys.include?(line) }
    
    run("mkdir -p -m 700 ~#{user}/.ssh")
    put authorized_keys.join("\n"), "~#{user}/.ssh/authorized_keys2", :mode => 0600
    run("chown -R #{user}.#{user} ~#{user}/.ssh")
  end
end