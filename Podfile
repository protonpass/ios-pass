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

# iOS
# All iOS child frameworks are linked statically for more optimal symbol stripping
# See Podfile of Drive for more information
target 'iOS' do
  platform :ios, '14.0'
#  pod 'ProtonCore-Log', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-OpenPGP', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Foundations', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-UIFoundations-V5', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-CoreTranslation', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-CoreTranslation-V5', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Utilities', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Challenge', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-DataModel', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Crypto', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Authentication/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Authentication-KeyGeneration/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Login/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Payments/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-PaymentsUI-V5/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-HumanVerification-V5/Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-ForceUpgrade-V5/Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-APIClient/Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Services/Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Networking/Alamofire', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Hash', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Doh', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-LoginUI-V5/UsingCrypto+Alamofire', :git => proton_core_path, :tag => proton_core_version
  project 'iOS/iOS'
end

target 'Client' do
  platform :ios, '14.0'
  use_frameworks! :linkage => :static
#  pod 'ProtonCore-Utilities', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Log', :git => proton_core_path, :tag => proton_core_version
#  pod 'ProtonCore-Doh', :git => proton_core_path, :tag => proton_core_version
  project 'Client/Client'
end

target 'Core' do
  platform :ios, '14.0'
  use_frameworks! :linkage => :static
  project 'Core/Core'
end

# TARGETS - MAC
# All macOS targets are linked dynamically ~> need to include pods of child frameworks into parent targets

target 'macOS' do
  platform :osx, '11.0'
  project 'macOS/macOS'
end
