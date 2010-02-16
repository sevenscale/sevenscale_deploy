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

    if outer_namespace
      shared_gems_subdir = options[:shared_subdir] || "#{outer_namespace}_gems"
    else
      shared_gems_subdir = options[:shared_subdir] || "bundler_gems"
    end

    # Default to bundler 0.8
    if options[:rails]
      release_gem_root = options[:gem_root] || 'vendor/bundler_gems'
    else
      release_gem_root = options[:gem_root] || 'vendor/gems'
    end

    release_gem_subdir = options[:gem_subdir] || 'ruby/1.8'

    directories_for_shared = %w(gems specifications dirs)

    if options[:cache_cache]
      directories_for_shared << 'cache'
    end

    tasks = lambda do
      namespace :bundler do
        desc "Symlink the vendored directories to shared"
        task :symlink_vendor, :roles => options[:roles] do
          bundle_root  = File.join(release_path, bundle_root_subdir.to_s)
          shared_gems  = File.join(shared_path,  shared_gems_subdir)
          release_gems = File.join(bundle_root,  release_gem_root, release_gem_subdir)

          cmd = directories_for_shared.collect do |sub_dir|
            shared_sub_dir = File.join(shared_gems, sub_dir)
            "mkdir -p #{shared_sub_dir} && mkdir -p #{release_gems} && ln -s #{shared_sub_dir} #{release_gems}/#{sub_dir}"
          end.join(' && ')

          run(cmd)
        end

        desc "Run bundler on a new release"
        task :bundle_new_release, :roles => options[:roles] do
          bundle_root  = File.join(release_path, bundle_root_subdir.to_s)
          release_gems = File.join(bundle_root,  release_gem_root, release_gem_subdir)

          cmd = "cd #{bundle_root} && bundle install #{release_gems}"

          bundler.symlink_vendor
          run(cmd)
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
        minimum_version          = '0.9.0'
        minumim_rubygems_version = '1.3.5'

        commands = [
          "system(*%w(gem update --system)) if Gem::Version.new(Gem::RubyGemsVersion) < Gem::Version.new(%(#{minumim_rubygems_version}))",
          "system(*%w(gem uninstall bundler -v) << %(< #{minimum_version})) if Gem.available?(%(bundler), %(< #{minimum_version}))",
          "system(*%w(gem install bundler -v) << %(~> #{minimum_version})) unless Gem.available?(%(bundler), %(~> #{minimum_version}))"
          ]

        sudo(%(/bin/sh -c "ruby -rubygems -e '#{commands.join("; ")}'"), :shell => false)
      end
    end

    unless options[:hook] == false
      our_hook_name = if outer_namespace
        "#{outer_namespace}:bundler:bundle_new_release"
      else
        "bundler:bundle_new_release"
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