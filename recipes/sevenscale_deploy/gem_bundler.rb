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
      release_gems_subdir = options[:gem_root] || 'vendor/bundler_gems/ruby/1.8'
    else
      release_gems_subdir = options[:gem_root] || 'vendor/gems/ruby/1.8'
    end

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
          release_gems = File.join(bundle_root,  release_gems_subdir)

          cmd = directories_for_shared.collect do |sub_dir|
            shared_sub_dir = File.join(shared_gems, sub_dir)
            "mkdir -p #{shared_sub_dir} && mkdir -p #{release_gems} && ln -s #{shared_sub_dir} #{release_gems}/#{sub_dir}"
          end.join(' && ')

          run(cmd)
        end

        desc "Run bundler on a new release"
        task :bundle_new_release, :roles => options[:roles] do

          bundle_root  = File.join(release_path, bundle_root_subdir.to_s)
          cmd = "cd #{bundle_root} && gem bundle"

          if only = options[:only]
            only = only.call if only.respond_to?(:call)
            cmd << " --only #{only}"
          end

          bundler.symlink_vendor
          run(cmd)
        end
      end
    end

    namespace(outer_namespace, &tasks) if outer_namespace

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

      after after_hook, our_hook_name
    end
  end
end

Capistrano.plugin :gem_bundler, GemBundler