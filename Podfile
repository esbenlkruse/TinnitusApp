# Uncomment the next line to define a global platform for your project
# platform :ios, '12.0'

source 'https://github.com/CocoaPods/Specs.git'
target 'Tinnitus' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  #use_frameworks!

  # Pods for Tinnitus
    pod 'Firebase'
    pod 'Firebase/Core'
    pod 'Firebase/Auth'
    pod 'Firebase/Database'
    pod 'Alamofire', '~> 4.7'
    pod 'GoogleMaps'
    pod 'Google-Maps-iOS-Utils'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        end
    end
end

target 'Tinnitus WatchKit App' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Tinnitus WatchKit App
end

target 'Tinnitus WatchKit App Extension' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Tinnitus WatchKit App Extension
  pod 'Alamofire', '~> 4.7'
end
