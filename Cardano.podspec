Pod::Spec.new do |s|
  s.name             = 'Cardano'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Cardano network.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Cardano.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_versions = ['5.3']
  
  s.module_name = 'Cardano'
  
  s.subspec 'Binary' do |ss|
    ss.source_files = 'Sources/Cardano/*.swift'

    ss.dependency 'Cardano-Binaries', '~> 0.0.1'
    
    ss.pod_target_xcconfig = {
      'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_XCFRAMEWORKS_BUILD_DIR}/CCardano"',
      'ENABLE_BITCODE' => 'NO'
    }
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
    end
  end

  s.subspec 'Build' do |ss|
    ss.source_files = 'Sources/Cardano/*.swift'
    ss.preserve_paths = "rust/**/*"
    
    ss.script_phase = {
      :name => "Build Rust Binary",
      :script => 'bash "${PODS_TARGET_SRCROOT}/rust/scripts/xcode_build_step.sh"',
      :execution_position => :before_compile
    }
    
    ss.pod_target_xcconfig = {
      'ENABLE_BITCODE' => 'NO'
    }
    
    ss.test_spec 'CardanoTests' do |test_spec|
      test_spec.source_files = 'Tests/CardanoTests/**/*.swift'
    end
  end

  s.default_subspecs = 'Binary'
end
