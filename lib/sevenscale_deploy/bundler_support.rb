module SevenScaleDeploy
  module BundlerSupport
    def bundler_dependencies(options = {})
      root = options.delete(:root)

      require 'bundler'
      Bundler::LockfileParser.new(File.read(File.join(root, 'Gemfile.lock'))).specs.each do |spec|
        gem_name = spec.name

        dependent_recipe = "#{gem_name.gsub(/-/, '_')}_gem_dependencies".to_sym
        if method_defined?(dependent_recipe)
          recipe(dependent_recipe, options)
        end
      end
    end
  end
end