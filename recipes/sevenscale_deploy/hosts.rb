Capistrano::Configuration.instance(:must_exist).load do
  namespace :hosts do
    desc "Update hostname to match deployment spec"
    task :update_hostname do
      sudo %{/bin/sh -c "ruby -npi~ -e 'gsub(/HOSTNAME=.*/, %{HOSTNAME=$CAPISTRANO:HOST$})' /etc/sysconfig/network && /bin/hostname $CAPISTRANO:HOST$"}
    end

    desc "Update /etc/hosts to include hostname"
    task :update do
      hosts = find_servers.collect { |s| s.host }.uniq

      hosts.each do |host|
        short_host = host[/^([^\.]+)/, 1]
        host_ip    = IPSocket.getaddress(host)

        etc_hosts = capture('cat /etc/hosts', :hosts => host)

        hosts_lines = etc_hosts.split(/\r?\n/).collect do |line|
          if line.match(/\b#{short_host}\b/)
            ip, hosts = line.split(/\s+/, 2)

            if ip == '127.0.0.1'
              line.gsub!(/\b(#{host}|#{short_host})\b/, '')
            else
              line = nil
            end
          end
          line
        end

        hosts_lines << "#{host_ip}\t#{host} #{short_host}\n"

        tmp_hosts_file = "/tmp/.etc.hosts.#{$$}"

        put hosts_lines.compact.join("\n"), tmp_hosts_file, :hosts => host

        sudo %{/usr/bin/install -b -m 644 -o root -g root #{tmp_hosts_file} /etc/hosts && rm #{tmp_hosts_file}}, :hosts => host
      end
    end
  end
end