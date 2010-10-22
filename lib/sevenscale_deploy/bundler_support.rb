module SevenScaleDeploy
  module BundlerSupport
    def bundler_dependencies(options = {})
      root = options.delete(:root)
      
      # Create something to communicate over
      r, w = IO.pipe

      fork do
        # Close the read side in the child
        r.close
        
        begin
          # Make sure we're using the right version of bundler
          Gem.activate 'bundler', '~> 1.0.3'
          require 'bundler'
          definition = Bundler::Definition.build(File.join(root, 'Gemfile'), File.join(root, 'Gemfile.lock'), nil)
          w.puts YAML::dump(:gems => definition.specs.map { |spec| spec.name })
        rescue Exception => e
          w.puts YAML::dump(:error => { :message => e.message, :class => e.class.name })
        end
        w.close
      end
      
      w.close
      response = YAML::load(r.read)
      r.close
      
      if response[:error]
        raise "#{response[:error][:class]}: #{response[:error][:message]}"
      else
        response[:gems].each do |gem_name|
          dependent_recipe = "#{gem_name.gsub(/-/, '_')}_gem_dependencies".to_sym
          if method_defined?(dependent_recipe)
            recipe(dependent_recipe, options)
          end
        end
      end
    end
  end
end
