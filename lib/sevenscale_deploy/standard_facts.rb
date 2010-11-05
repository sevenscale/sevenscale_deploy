Facter.add(:rails_env) do
  setcode do
    ENV["RAILS_ENV"] || 'production'
  end
end

Facter.add(:rails_root) do
  setcode do
    ENV["RAILS_ROOT"] || Dir.pwd
  end
end

Facter.add(:operatingsystemflavor) do
  setcode do
    case Facter.operatingsystem
    when 'RedHat', 'Fedora', 'CentOS'
      'RedHat'
    when 'Ubuntu', 'Debian'
      'Debian'
    else
      Facter.operatingsystem
    end
  end
end

Facter.add(:first_capistrano_role) do
  setcode do
    ENV['CAPISTRANO_ROLES'].to_s.split(',').first
  end
end

def Facter.case(name, whens)
  if whens[:default].is_a?(Exception)
    default = proc { raise whens[:default] }
  elsif whens[:default].is_a?(Proc)
    default = whens[:default]
  elsif whens[:default]
    default = proc { whens[:default] }
  else
    default = proc { |value| raise "Unsupported case for '#{name}': #{value}" }
  end

  if value = self.value(name)
    if result = whens[value]
      return result
    else
      return default.call(value)
    end
  else
    raise "No value was returned for '#{name}'"
  end
end
