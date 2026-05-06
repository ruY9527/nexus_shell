platform :ios, '17.0'

target 'nexus_shell' do
  use_frameworks!
  
  pod 'NMSSH', '~> 2.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      
      # Suppress library target mismatch errors
      xcconfig = config.build_settings['OTHER_LDFLAGS'] || '$(inherited)'
      config.build_settings['OTHER_LDFLAGS'] = "#{xcconfig} -Wl,-no_warn_duplicate_libraries"
    end
  end
end
