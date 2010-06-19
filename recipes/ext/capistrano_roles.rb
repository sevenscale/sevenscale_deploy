::Capistrano::Command.class_eval do
  def replace_placeholders(command, channel)
    command = command.dup
    command.gsub!(/\$CAPISTRANO:HOST\$/, channel[:host])
    command.gsub!(/\$CAPISTRANO:ROLES\$/, channel[:server].roles.join(','))
    command
  end
end

::Capistrano::ServerDefinition.class_eval do
  attr_accessor :roles
end

::Capistrano::Configuration.class_eval do
  def find_servers_with_role_attr(*args)
    servers = find_servers_without_role_attr(*args)

    servers.each do |server|
      server.roles = self.roles.select { |name, server_list| server_list.include?(server) }.map { |name, _| name }
    end

    servers
  end

  alias_method :find_servers_without_role_attr, :find_servers
  alias_method :find_servers, :find_servers_with_role_attr
end
