require "#{File.dirname(__FILE__)}/../../../moonshine/lib/moonshine"

require 'sevenscale_deploy/bundler_support'
require 'sevenscale_deploy/source_package'
require 'sevenscale_deploy/fact_based_overrides'
require 'sevenscale_deploy/standard_facts'

module SevenScaleDeploy
  class BasicManifest < Moonshine::Manifest
    require 'active_support/core_ext/hash'

    # Let's make strings work for keys for reading and writing
    write_inheritable_attribute(:__config__, read_inheritable_attribute(:__config__).with_indifferent_access)

    def self.configuration
      __config__
    end

    def self.configure(hash)
      __config__.replace(__config__.to_hash.deep_merge(hash).with_indifferent_access)
    end

    # Perform fact-specific overrides
    include SevenScaleDeploy::FactBasedOverrides

    include SevenScaleDeploy::SourcePackage
    include SevenScaleDeploy::BundlerSupport

    private
    def unindent(string)
      indentation = string[/\A\s*/]
      string.strip.gsub(/^#{indentation}/, "") + "\n"
    end

    # Do this to work with moonshine plugins
    def gem(name, options = {})
      package name, options.merge(:provider => :gem)
    end
  end
end