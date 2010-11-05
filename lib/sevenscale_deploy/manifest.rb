require "#{File.dirname(__FILE__)}/../../../moonshine/lib/moonshine"

require 'sevenscale_deploy/basic_manifest'
require 'sevenscale_deploy/standard_packages'
require 'sevenscale_deploy/standard_facts'

module SevenScaleDeploy
  class Manifest < SevenScaleDeploy::BasicManifest
    include Moonshine::Manifest::Rails::Os
    include SevenScaleDeploy::StandardPackages
    include SevenScaleDeploy::Passenger
  end
end