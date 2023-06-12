def proton_core_path
  'git@gitlab.protontech.ch:apple/shared/protoncore.git'
end

def proton_core_version
  '7.1.0'
end
  
def pmtest_path
  'git@gitlab.protontech.ch:tpe/apple-fusion.git'
end

def pmtest_commit
  "1ba256d5"
end

def crypto_variant
  "Crypto-Go"
end

def client_and_ios_pods
  pod 'ProtonCore-Log', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Utilities', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Doh', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-DataModel', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-CryptoGoInterface", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-CryptoGoImplementation/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-GoLibs/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Keymaker/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Networking', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Environment', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-FeatureSwitch', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Login/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'TrustKit', :git=> 'https://github.com/ProtonMail/TrustKit.git', :tag => '1.0.3', :inhibit_warnings => true
  pod 'ProtonCore-UIFoundations', :git => proton_core_path, :tag => proton_core_version
end

def ios_and_uicomponents
  pod 'ProtonCore-CoreTranslation', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-CoreTranslation', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-UIFoundations', :git => proton_core_path, :tag => proton_core_version
end

target 'Client' do
  platform :ios, '15.0'
  use_frameworks!

  client_and_ios_pods
  pod 'SwiftProtobuf', '1.20.3'
  pod "ProtonCore-KeyManager/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ReachabilitySwift'

  target 'ClientTests' do
  end
  
  target 'iOSTests' do
    platform :ios, '15.0'
    use_frameworks!

    pod 'swift-snapshot-testing', :git => proton_core_path, :tag => proton_core_version
    pod "ProtonCore-TestingToolkit/UnitTests/Core", :git => proton_core_path, :tag => proton_core_version
  end

end

target 'Core' do
  platform :ios, '15.0'
  use_frameworks!

  pod 'ProtonCore-DataModel', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Log', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Utilities', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Doh', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Keymaker/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Networking', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Observability', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Crypto/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-LoginUI/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-TroubleShooting', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Settings', :git => proton_core_path, :tag => proton_core_version

  target 'CoreTests' do
    pod "ProtonCore-GoLibs/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
    pod "ProtonCore-TestingToolkit/UnitTests/Core", :git => proton_core_path, :tag => proton_core_version
  end

end

target 'UIComponents' do
  platform :ios, '15.0'
  use_frameworks!
  ios_and_uicomponents
end

target 'iOS' do
  platform :ios, '15.0'
  use_frameworks!

  client_and_ios_pods
  ios_and_uicomponents
  pod 'ProtonCore-OpenPGP', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Foundations', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Challenge', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Authentication/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Authentication-KeyGeneration/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Payments/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-PaymentsUI/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-HumanVerification/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-ForceUpgrade', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-APIClient', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Services', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Networking', :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-Hash', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-LoginUI/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'ProtonCore-TroubleShooting', :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-AccountDeletion/#{crypto_variant}", :git => proton_core_path, :tag => proton_core_version
  pod 'MBProgressHUD'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.29.0'

  target 'AutoFill' do
    inherit! :search_paths
  end

end

target "iOSUITests" do
  platform :ios, '15.0'
  use_frameworks!
  
  pod "ProtonCore-ObfuscatedConstants", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-Doh", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-QuarkCommands", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-TestingToolkit/TestData", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-TestingToolkit/UITests/Core", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-TestingToolkit/UITests/Login", :git => proton_core_path, :tag => proton_core_version
  pod "ProtonCore-TestingToolkit/UITests/PaymentsUI", :git => proton_core_path, :tag => proton_core_version
  pod 'swift-snapshot-testing', :git => proton_core_path, :tag => proton_core_version
  pod "fusion", :git => "git@gitlab.protontech.ch:tpe/apple-fusion.git", :commit => "1ba256d5"
end


target 'macOS' do
  platform :macos, '12.0'
  use_frameworks!
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
      config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "12.0"
      config.build_settings['ENABLE_BITCODE'] = 'No'
      if config.name == "Debug" || config.name == "Debug-QA"
        config.build_settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) DEBUG"
      end
    end
  end
end
