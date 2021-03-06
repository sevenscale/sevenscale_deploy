require "#{File.dirname(__FILE__)}/../../../moonshine/lib/moonshine"

require 'moonshine/manifest/rails'
require 'sevenscale_deploy/basic_manifest'
require 'sevenscale_deploy/standard_packages'
require 'sevenscale_deploy/standard_facts'
require 'sevenscale_deploy/passenger'

module SevenScaleDeploy
  class Manifest < SevenScaleDeploy::BasicManifest
    include Moonshine::Manifest::Rails::Os
    include SevenScaleDeploy::StandardPackages
    include SevenScaleDeploy::Passenger
  end
end