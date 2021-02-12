Pod::Spec.new do |s|
  s.name             = 'Cardano'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Cardano network.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Cardano.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '6.0'
  
  s.swift_versions = ['5', '5.1', '5.2']
  
  s.module_name = 'Cardano'
  
  s.subspec 'Binary' do |ss|
    ss.source_files = 'Sources/Cardano/**/*.swift'

    ss.dependency 'Cardano/RustBinary'
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
      test_spec.platforms = {:ios => '10.0', :osx => '10.12', :tvos => '10.0'}
    end
  end
  
  s.subspec 'Sources' do |ss|
    ss.source_files = 'Sources/Cardano/**/*.swift'

    ss.dependency 'Cardano/RustSources'
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
      test_spec.platforms = {:ios => '10.0', :osx => '10.12', :tvos => '10.0'}
    end
  end

  s.subspec 'RustBinary' do |ss|
    ss.pod_target_xcconfig = {
      "HEADER_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/Sources/CCardano/include",
      "LIBRARY_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/Sources/CCardano"
      "OTHER_LIBTOOLFLAGS" => "-lcardano_c",
      "ENABLE_BITCODE" => "NO"
    }

    ss.preserve_paths = "Sources/CCardano/**/*"
  end

  s.subspec 'RustSources' do |ss|
    ss.script_phase = {
      :name => "Build Rust Binary",
      :script => 'bash "${PODS_TARGET_SRCROOT}/xcode_build_step.sh"',
      :execution_position => :before_compile
    }

    ss.pod_target_xcconfig = {
      "HEADER_SEARCH_PATHS" => "$(CONFIGURATION_BUILD_DIR)",
      "OTHER_LIBTOOLFLAGS" => "-lcardano_c",
      "ENABLE_BITCODE" => "NO"
    }

    ss.preserve_paths = "rust/**/*"
  end

  s.default_subspecs = 'Binary'
end
