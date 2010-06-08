namespace :locald do
  desc 'Create a local.d for local configuration settings'
  task :apply do

    hosts_in_need = locald.find_hosts_in_need('grep -c local.d /etc/rc.d/rc.local') { |out| out.to_i > 0 }

    unless hosts_in_need.empty?
      run %{(echo ; echo '# Local startup scripts to execute'; echo 'for i in /etc/rc.d/local.d/*; . $i; done') | #{sudo} tee -a /etc/rc.d/rc.local > /dev/null}, :hosts => hosts_in_need
    end
  end

  def upload_local(contents)
    via            = fetch(:user) == 'root' ? :run : :sudo
    application    = fetch(:application)
    file_temporary = "/tmp/.local.d.#{application}.#{$$}"
    file_local     = "/etc/rc.d/local.d/#{application}"

    commands = []
    commands << "/usr/bin/install -T -b -m 0755 -o root -g root #{file_temporary} #{file_local}"
    commands << "rm -f #{file_temporary}"

    put contents, file_temporary, :mode => 0440
    invoke_command %{/bin/sh -c "#{commands.join(' && ')}"}, :via => via
  rescue
    # Remove sudoers lock file
    invoke_command "rm -f #{file_temporary}", :via => via
    raise
  end

  def find_hosts_in_need(command, &block)
    all_servers    = Set.new
    passed_servers = Set.new

    begin
      invoke_command(command) do |ch,stream,out|
        all_servers << ch[:server]

        if block.call(out)
          passed_servers << ch[:server]
        end
      end
    rescue Capistrano::CommandError
    end


    all_servers - passed_servers
  end
end