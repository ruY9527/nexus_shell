platform :ios, '15.0'

target 'nexus_shell' do
  use_modular_headers!
  # NMSSH vendored static libs are incompatible with current Xcode toolchain
  # pod 'NMSSH', '~> 2.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
