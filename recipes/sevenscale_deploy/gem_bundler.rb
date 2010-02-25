module GemBundler
  # options:
  #   :bundle_root
  #   :shared_subdir
  #   :gem_root
  #   :rails
  #   :cache_cache
  #   :only
  #
  # gem_bundler.bundle :rails => true, :only => rails_env
  # gem_bundler.bundle :downloader
  #
  def bundle(*args)
    options         = args.last.is_a?(Hash) ? args.pop : {}
    outer_namespace = args.first

    bundle_root_subdir = options[:bundle_root] || outer_namespace

    tasks = lambda do
      namespace :bundler do
        desc "Run bundler on a new release"
        task :bundle, :roles => options[:roles] do
          bundle_root     = File.join(release_path, bundle_root_subdir.to_s)
          shared_root_dir = File.join(shared_path, 'bundler')

          run "cd #{bundle_root} && bundle install #{shared_root_dir}"
        end
      end
    end

    if outer_namespace
      namespace(outer_namespace, &tasks)
    else
      tasks.call
    end

    namespace :bundler do
      desc 'Install correct version of gem bundler'
      task :install do
        minimum_version          = '0.9.7'
        minumim_rubygems_version = '1.3.5'

        commands = [
          "system(*%w(gem update --system)) if Gem::Version.new(Gem::RubyGemsVersion) < Gem::Version.new(%(#{minumim_rubygems_version}))",
          "system(*%w(gem uninstall bundler -I -x -v) << %(< #{minimum_version})) if Gem.available?(%(bundler), %(< #{minimum_version}))",
          "system(*%w(gem install bundler -v) << %(~> #{minimum_version})) unless Gem.available?(%(bundler), %(~> #{minimum_version}))"
          ]

        sudo(%(/bin/sh -c "ruby -rubygems -e '#{commands.join("; ")}'"), :shell => false)
      end
    end

    unless options[:hook] == false
      our_hook_name = if outer_namespace
        "#{outer_namespace}:bundler:bundle"
      else
        "bundler:bundle"
      end

      after_hook = if options[:hook].is_a?(String)
        options[:hook]
      else
        'deploy:finalize_update'
      end

      # Make sure the gem bundler is installed
      after after_hook, 'bundler:install'

      # Run the gem bundler for us
      after after_hook, our_hook_name
    end
  end
end

Capistrano.plugin :gem_bundler, GemBundler
