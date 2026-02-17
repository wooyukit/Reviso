platform :ios, '17.0'

target 'Reviso' do
  use_frameworks!

  pod 'Kingfisher', '~> 8.0'

  target 'RevisoTests' do
    inherit! :search_paths
  end

  target 'RevisoUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end

  # Disable sandbox for CocoaPods script phases (Xcode 26 compatibility)
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  end
end
