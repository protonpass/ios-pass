source 'https://github.com/CocoaPods/Specs.git'
workspace 'ProtonKey'
use_frameworks!
install! 'cocoapods', :deterministic_uuids => false

def proton_core_path
  'git@gitlab.protontech.ch:apple/shared/protoncore.git'
end

def proton_core_version
  "3.18.0"
end

def pmtest_path
  'git@gitlab.protontech.ch:apple/shared/pmtestautomation.git'
end

def pmtest_commit
  "2bc09250d65786c316aa8a2a203404ada745bea2"
end

# Pods
def for_uicomponents
  pod 'ProtonCore-UIFoundations-V5', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Foundations', :git => proton_core_path, :tag => proton_core_version
end

def for_client
  pod 'ProtonCore-Networking/Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Services/Alamofire', :git => proton_core_path, :tag => proton_core_version
end

def for_authentication
  pod 'ProtonCore-Authentication/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Services/Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-APIClient/Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Log', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-DataModel', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Doh', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Utilities', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-CoreTranslation', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-CoreTranslation-V5', :git => proton_core_path, :tag => proton_core_version
end

def for_core
  for_authentication
  
  pod 'ProtonCore-Crypto', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Keymaker/UsingCrypto', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-KeyManager/UsingCrypto', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Payments/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version

  # pod 'TrustKit', :git => 'https://github.com/ProtonMail/TrustKit.git', :branch => 'release/1.0.0'
  # pod 'EllipticCurveKeyPair', :git => 'https://github.com/agens-no/EllipticCurveKeyPair.git', :tag => '2.0'

  # pod 'Sentry', '4.1.0'
end


# iOS
# All iOS child frameworks are linked statically for more optimal symbol stripping
# See Podfile of Drive for more information

target 'iOS' do
  platform :ios, '14.0'
  project 'iOS/iOS'
end

target 'UIComponents' do
  platform :ios, '14.0'
  use_frameworks! :linkage => :static

  for_uicomponents

  pod 'ProtonCore-Settings-V5', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Login/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-LoginUI-V5/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Payments/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Hash', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-PaymentsUI-V5/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Authentication-KeyGeneration/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Challenge', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-HumanVerification-V5/Alamofire', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-OpenPGP', :git => proton_core_path, :tag => proton_core_version

  project 'UIComponents/UIComponents'
end

target 'Client' do
  platform :ios, '14.0'
  use_frameworks! :linkage => :static

  for_client

  project 'Client/Client'
end

target 'Core' do
  platform :ios, '14.0'
  use_frameworks! :linkage => :static

  for_core

  project 'Core/Core'
end

# TARGETS - MAC
# All macOS targets are linked dynamically ~> need to include pods of child frameworks into parent targets

target 'macOS' do
  platform :osx, '11.0'

  for_core
  for_uicomponents

  project 'macOS/macOS'
end

# TAGETS - TESTS

# target 'PDClientUnitTests' do
#   platform :ios, '14.1'
#   use_frameworks! :linkage => :static
#   inherit! :search_paths

#   for_authentication

#   project 'PDClient/PDClient'
# end

# target 'PDClientIntegrationTests' do
#   platform :ios, '14.1'
#   use_frameworks! :linkage => :static
#   inherit! :search_paths

#   for_authentication
  
#   pod 'pmtest', :git => pmtest_path, :commit => pmtest_commit
#   pod 'ProtonCore-QuarkCommands/Alamofire', :git => proton_core_path, :tag => proton_core_version

#   project 'PDClient/PDClient'
# end

# target 'PDCoreUnitTests' do
#   platform :ios, '14.1'
#   inherit! :search_paths
#   use_frameworks! :linkage => :static

#   pod 'ProtonCore-Networking/Alamofire', :git => proton_core_path, :tag => proton_core_version
#   pod 'ProtonCore-TestingToolkit/UnitTests/Core', :git => proton_core_path, :tag => proton_core_version
#   pod 'pmtest', :git => pmtest_path, :commit => pmtest_commit
#   pod 'ProtonCore-QuarkCommands/Alamofire', :git => proton_core_path, :tag => proton_core_version
  
#   # MARK: for Kris - uncommenting next line will cause Cocoapods to search for ProtonCore-Authentication/UsingCryptoVPN which we can not allow because it depends on CryptoVPN which conflicts with our Crypto
#   pod 'ProtonCore-TestingToolkit/UnitTests/Login/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version

#   project 'PDCore/PDCore'
# end

# target 'PDCoreIntegrationTests' do
#   platform :ios, '14.1'
#   inherit! :search_paths
#   use_frameworks! :linkage => :static

#   pod 'ProtonCore-Networking/Alamofire', :git => proton_core_path, :tag => proton_core_version
#   pod 'ProtonCore-TestingToolkit/UnitTests/Core', :git => proton_core_path, :tag => proton_core_version
#   pod 'pmtest', :git => pmtest_path, :commit => pmtest_commit
#   pod 'ProtonCore-QuarkCommands/Alamofire', :git => proton_core_path, :tag => proton_core_version
  
#   # MARK: for Kris - uncommenting next line will cause Cocoapods to search for ProtonCore-Authentication/UsingCryptoVPN which we can not allow because it depends on CryptoVPN which conflicts with our Crypto
#   pod 'ProtonCore-TestingToolkit/UnitTests/Login/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version

#   project 'PDCore/PDCore'
# end

# target 'ProtonDriveTests' do
#   platform :ios, '14.1'
#   inherit! :search_paths

#   use_frameworks! :linkage => :static
#   pod 'ProtonCore-TestingToolkit/UnitTests/Core', :git => proton_core_path, :tag => proton_core_version
#   pod 'ProtonCore-TestingToolkit/UnitTests/Doh', :git => proton_core_path, :tag => proton_core_version
#   pod 'ProtonCore-TestingToolkit/UnitTests/HumanVerification-V5/Alamofire', :git => proton_core_path, :tag => proton_core_version

#   # MARK: for Kris - uncommenting next line will cause Cocoapods to search for ProtonCore-Authentication/UsingCryptoVPN which we can not allow because it depends on CryptoVPN which conflicts with our Crypto
#   pod 'ProtonCore-TestingToolkit/UnitTests/Login/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#   pod 'ProtonCore-TestingToolkit/UnitTests/Services/Alamofire', :git => proton_core_path, :tag => proton_core_version

#   project 'ProtonDrive-iOS/ProtonDrive-iOS'
# end

# target 'PDFileProviderTests' do
#   platform :ios, '14.1'
#   inherit! :search_paths
#   use_frameworks! :linkage => :static

#   project 'PDFileProvider/PDFileProvider'
# end

# target 'ProtonDriveUITests' do
#   platform :ios, '14.1'
#   inherit! :search_paths

#   use_frameworks! :linkage => :static
#   pod 'ProtonCore-TestingToolkit/UITests/HumanVerification', :git => proton_core_path, :tag => proton_core_version
#   pod 'pmtest', :git => pmtest_path, :commit => pmtest_commit
#   pod 'SwiftOTP', '~> 2.0.3'
#   pod 'OHHTTPStubs/Swift', '9.0.0'

#   project 'ProtonDrive-iOS/ProtonDrive-iOS'
# end


# # POST INSTALL

# post_install do |installer_representation|
#   require 'fileutils'
#   FileUtils.cp_r('Pods/Target Support Files/Pods-ProtonDrive/Pods-ProtonDrive-Acknowledgements.markdown', 'ProtonDrive-iOS/ProtonDrive/Acknowledgements.markdown', :remove_destination => true)

#   installer_representation.pods_project.targets.each do |target|
#     target.build_configurations.each do |config|
#       config.build_settings['ENABLE_BITCODE'] = 'No'
#     end
#   end
# end

