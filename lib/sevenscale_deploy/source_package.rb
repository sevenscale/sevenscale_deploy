module SevenScaleDeploy
  module SourcePackage
    def source_package(name, options = {})
      build_root         = options[:build_root]         || '/usr/src'
      dist_root          = options[:dist_root]          || File.join(build_root, 'dist')
      url                = options[:url]
      filename           = options[:filename]           || File.basename(url)
      expanded_directory = options[:expanded_directory] || filename[/^(.+)\.(tar|tgz|tbz)/, 1]
      expanded_root      = options[:expanded_root]      || File.join(build_root, expanded_directory)
      compression_scheme = options[:compression_scheme]
      if options[:stow]
        stow_root        = options[:stow].is_a?(String) ? options[:stow] : '/usr/local/stow'
        prefix           = options[:prefix]             || "#{stow_root}/#{expanded_directory}"
        stow_command     = options[:stow_command]       || "stow #{expanded_directory}"
        unstow_prefix    = options[:unstow_prefix]
        if unstow_prefix
          unstow_command = options[:unstow_command]     || "stow -D #{unstow_prefix}-*"
        end
        compile_command  = options[:compile_command]    || "./configure --prefix=#{prefix} && make"
      else
        prefix           = options[:prefix]             || '/usr/local'
        compile_command  = options[:compile_command]    || "./configure --prefix=#{prefix} && make"
      end
      install_command    = options[:install_command]    || 'make install'

      compile_command.gsub!('%PREFIX%', prefix)
      install_command.gsub!('%PREFIX%', prefix)

      # We're deleting these so they don't end up in the metadata file
      requirements       = Array(options.delete(:require))

      tar_options = guess_tar_options(filename, compression_scheme)

      dist_filename     = File.join(dist_root, filename)
      download_filename = File.join(dist_root, '.' + filename)

      metadata_content  = "Installed #{name} from #{url}:\n#{options.sort.to_yaml}"
      metadata_checksum = Digest::MD5.hexdigest(metadata_content)
      metadata_filename = File.join(expanded_root, 'source-package-installed')

      # We need this to trick puppet into not creating a requirement
      # See: http://projects.puppetlabs.com/issues/3873
      tricky_metadata_filename = File.join(expanded_root, '.', 'source-package-installed')

      unless_command = %{(test -f "#{tricky_metadata_filename}" -a "#{metadata_checksum}" = "`md5sum #{tricky_metadata_filename} | awk '{print $1}'`")}

      if options[:stow]
        file stow_root, :ensure => :directory

        case Facter.operatingsystem
        when 'RedHat', 'CentOS'
          source_package 'stow', :url => 'http://ftp.gnu.org/gnu/stow/stow-1.3.3.tar.gz'
          stow_dependency = file('source_package stow')
        else
          package 'stow', :ensure => :installed
          stow_dependency = package('stow')
        end
      end

      package 'curl', :ensure => :installed

      file '/usr/src/dist',
        :ensure => :directory,
        :owner  => 'root',
        :group  => 'root',
        :mode   => 0755

      exec "source_package fetch #{name}",
        :command => "curl -L -s -S -o #{download_filename} #{url} && mv #{download_filename} #{dist_filename}",
        :creates => dist_filename,
        :require => [ package('curl'), file('/usr/src/dist') ]

      exec "source_package untar #{name}",
        :command => "rm -rf #{expanded_root}; tar #{tar_options}xf #{dist_filename} -C #{build_root}",
        :unless  => unless_command,
        :require => exec("source_package fetch #{name}")

      exec "source_package compile #{name}",
        :command     => compile_command,
        :cwd         => expanded_root,
        :unless      => unless_command,
        :timeout     => 60 * 30, # Give it 30 minutes to compile
        :logoutput   => :on_failure,
        :require     => requirements + [ exec("source_package untar #{name}") ]

      exec "source_package install #{name}",
        :command     => install_command,
        :cwd         => expanded_root,
        :unless      => unless_command,
        :subscribe   => exec("source_package compile #{name}")

      if options[:stow]
        stow_requirements = [ file(stow_root), stow_dependency ]

        if unstow_command
          exec "source_package unstow #{name}",
            :command   => unstow_command,
            :cwd       => stow_root,
            :path      => '/bin:/usr/bin:/usr/local/bin:/opt/bin',
            :unless    => unless_command,
            :onlyif    => "test `ls -d1 #{stow_root}/#{unstow_prefix}-* | wc -l` -gt 1",
            :subscribe => exec("source_package install #{name}"),
            :require   => stow_requirements

          stow_requirements = stow_requirements + [ exec("source_package unstow #{name}") ]
        end

        exec "source_package stow #{name}",
          :command   => stow_command,
          :cwd       => stow_root,
          :path      => '/bin:/usr/bin:/usr/local/bin:/opt/bin',
          :unless    => unless_command,
          :subscribe => exec("source_package install #{name}"),
          :require   => stow_requirements

        file "source_package #{name}",
          :path      => metadata_filename,
          :content   => metadata_content,
          :require   => exec("source_package stow #{name}")
      else
        file "source_package #{name}",
          :path      => metadata_filename,
          :content   => metadata_content,
          :require   => exec("source_package install #{name}")
      end
    end

    def guess_tar_options(filename, compression_scheme)
      case compression_scheme
      when 'bzip2'
        tar_options = 'j'
      when 'gz', 'gzip'
        tar_options = 'z'
      when nil
        case filename
        when /\.bz2/, /\.tbz/
          tar_options = 'j'
        when /\.gz/, /\.tgz/
          tar_options = 'z'
        else
          raise "Unknown compression_scheme for filename: #{filename}"
        end
      else
        raise "Unknown compression_scheme: #{compression_scheme}"
      end

      tar_options
    end
  end
end