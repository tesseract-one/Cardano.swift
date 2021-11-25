Pod::Spec.new do |s|
  s.name             = 'Cardano-Binaries'
  s.version          = '0.1.2'
  s.summary          = 'Compiled Rust files for Cardano.swift.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "https://github.com/tesseract-one/Cardano.swift/releases/download/#{s.version.to_s}/CCardano.binaries.zip", :sha256 => '2352e340c34bea53d7a1877f9017d964f624b7a8d2a2fd41386ccdfa06846393' }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_versions = ['5.3', '5.4', '5.5']
  
  s.module_name = 'CCardano'
  
  s.vendored_frameworks = 'CCardano.xcframework'
end
