Pod::Spec.new do |s|
  s.name             = 'Cardano.swift'
  s.version          = '0.1.2'
  s.summary          = 'Swift APIs for Cardano network.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Cardano.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  # s.tvos.deployment_target = '13.0'
  
  s.swift_versions = ['5.3', '5.4', '5.5']
  
  s.module_name = 'Cardano'
  
  s.subspec 'OrderedCollections' do |ss|
    ss.source_files = 'Sources/OrderedCollections/**/*.swift'
  end
  
  s.subspec 'CoreBinary' do |ss|
    ss.source_files = 'Sources/Core/**/*.swift'

    ss.dependency 'Cardano-Binaries', '~> 0.1.2'
    ss.dependency 'BigInt', '~> 5.2'
    ss.dependency 'Cardano/OrderedCollections'
    
    ss.pod_target_xcconfig = {
      'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_XCFRAMEWORKS_BUILD_DIR}/Cardano-Binaries"',
      'ENABLE_BITCODE' => 'NO'
    }
    
    ss.test_spec 'CoreTests' do |test_spec|
      test_spec.source_files = 'Tests/CoreTests/**/*.swift'
    end
  end

  s.subspec 'CoreBuild' do |ss|
    ss.source_files = 'Sources/Core/**/*.swift'
    ss.preserve_paths = "rust/**/*"
    
    ss.dependency 'BigInt', '~> 5.2'
    ss.dependency 'Cardano/OrderedCollections'
    
    ss.script_phase = {
      :name => "Build Rust Binary",
      :script => 'bash "${PODS_TARGET_SRCROOT}/rust/scripts/xcode_build_step.sh"',
      :execution_position => :before_compile
    }
    
    ss.pod_target_xcconfig = {
      'ENABLE_BITCODE' => 'NO'
    }
    
    ss.test_spec 'CoreTests' do |test_spec|
      test_spec.source_files = 'Tests/CoreTests/**/*.swift'
    end
  end
  
  s.subspec 'Binary' do |ss|
    ss.source_files = 'Sources/Cardano/**/*.swift'
    
    ss.dependency 'Bip39.swift', '~> 0.1'
    ss.dependency 'Cardano/CoreBinary'
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
    end
  end
  
  s.subspec 'Build' do |ss|
    ss.source_files = 'Sources/Cardano/**/*.swift'
    
    ss.dependency 'Bip39.swift', '~> 0.1'
    ss.dependency 'Cardano/CoreBuild'
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
    end
  end
  
  s.subspec 'Blockfrost' do |ss|
    ss.source_files = 'Sources/Blockfrost/**/*.swift'
    
    ss.dependency 'BlockfrostSwiftSDK', '~> 0.0.5'
    ss.dependency 'Cardano/Binary'
  end
  
  s.subspec 'BlockfrostBuild' do |ss|
    ss.source_files = 'Sources/Blockfrost/**/*.swift'
    
    ss.dependency 'BlockfrostSwiftSDK', '~> 0.0.5'
    ss.dependency 'Cardano/Build'
  end
  
  s.default_subspecs = 'Binary'
end
