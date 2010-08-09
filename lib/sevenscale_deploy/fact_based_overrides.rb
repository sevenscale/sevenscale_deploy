module SevenScaleDeploy
  module FactBasedOverrides
    def self.included(base)
      # Perform fact-specific overrides
      if base.configuration[:overrides].respond_to?(:each)
        base.configuration[:overrides].each do |key, overrides|
          if override = overrides[Facter.value(key)] rescue nil
            base.configure(override)
          end
        end
      end
    end
  end
end