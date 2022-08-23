Pod::Spec.new do |s|
  s.name             = 'Cardano.swift'
  s.version          = '0.1.4'
  s.summary          = 'Swift APIs for Cardano network.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Cardano.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  # s.tvos.deployment_target = '13.0'
  
  s.swift_version = '5.4'
  
  s.module_name = 'Cardano'
  
  s.subspec 'Cardano' do |ss|
    ss.dependency 'OrderedCollections', '~> 1.0.2'
    ss.dependency 'BigInt', '~> 5.2'
    ss.dependency 'Bip39.swift', '~> 0.1.1'
    
    ss.source_files = 'Sources/Cardano/**/*.swift', 'Sources/Core/**/*.swift'
    
    ss.pod_target_xcconfig = {
      'ENABLE_BITCODE' => 'NO'
    }
    
    ss.subspec 'Binary' do |sss|
      sss.dependency 'Cardano-Binaries', '~> 0.1.4'
      
      sss.pod_target_xcconfig = {
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_XCFRAMEWORKS_BUILD_DIR}/Cardano-Binaries"',
        'CARDANO_USES_BINARY_RUST_XCFRAMEWORK' => 'YES'
      }
    end
    
    ss.subspec 'Build' do |sss|
      sss.preserve_paths = "rust/**/*"
    
      sss.script_phase = {
        :name => "Build Rust Binary",
        :script => 'bash "${PODS_TARGET_SRCROOT}/rust/scripts/xcode_build_step.sh"',
        :execution_position => :before_compile
      }
    end
    
    ss.test_spec 'CoreTests' do |test_spec|
      test_spec.source_files = 'Tests/CoreTests/**/*.swift'
    end
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
    end
  end
  
  s.subspec 'Blockfrost' do |ss|
    ss.source_files = 'Sources/Blockfrost/**/*.swift'
    ss.dependency 'BlockfrostSwiftSDK', '~> 0.0.7'
    ss.dependency 'Cardano.swift/Cardano'
  end
  
  s.default_subspecs = 'Cardano/Binary', 'Blockfrost'
end
