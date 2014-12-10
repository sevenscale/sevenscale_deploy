module SevenScaleDeploy
  module BundlerSupport
    def bundler_dependencies(options = {})
      root = options.delete(:root)
      
      parse_gemfile_lock(File.join(root, 'Gemfile.lock')).each do |gem_name|
        dependent_recipe = "#{gem_name.gsub(/-/, '_')}_gem_dependencies".to_sym
        if method_defined?(dependent_recipe)
          recipe(dependent_recipe, options)
        end
      end
    end

    def parse_gemfile_lock(lockfile)
      return parse_gemfile_lock_0_9(lockfile)
    rescue Exception
      return parse_gemfile_lock_1_0(lockfile)
    end

    def parse_gemfile_lock_1_0(lockfile)
      gems = []
      in_gem_list = in_specs_list = false
      
      File.read(lockfile).split(/(\r?\n)+/).each do |line|
        if mode = line[/^(\w+)$/, 1]
          if mode == 'GEM'
            in_gem_list = true
            in_specs_list = false
          elsif mode == 'DEPENDENCIES'
            in_gem_list = in_specs_list = true
          end

          next
        end

        if !in_specs_list && in_gem_list && line == '  specs:'
          in_specs_list = true
          next
        end

        if in_specs_list && gem_name = line[/^ +(.*?)(?: \(.*)?(?:!)?$/, 1]
          gems << gem_name
        end
      end

      gems.uniq
    end

    def parse_gemfile_lock_0_9(lockfile)
      gems = YAML::load_file(lockfile)['specs'].collect do |spec|
        spec.keys.first
      end.uniq
    end
  end
end
