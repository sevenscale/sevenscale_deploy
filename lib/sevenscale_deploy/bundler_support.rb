module SevenScaleDeploy
  module BundlerSupport
    def bundler_dependencies(options = {})
      root = options.delete(:root)

      # WARNING: This is highly Bundler 0.9 -specific
      YAML::load_file(File.join(root, 'Gemfile.lock'))['specs'].each do |spec|
        gem_name = spec.keys.first

        dependent_recipe = "#{gem_name.gsub(/-/, '_')}_gem_dependencies".to_sym
        if method_defined?(dependent_recipe)
          recipe(dependent_recipe, options)
        end
      end
    end
  end
end