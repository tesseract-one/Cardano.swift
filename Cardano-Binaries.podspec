Pod::Spec.new do |s|
  s.name             = 'Cardano-Binaries'
  s.version          = '0.0.1'
  s.summary          = 'Compiled Rust files for Cardano.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "https://github.com/tesseract-one/Cardano.swift/releases/download/#{s.version.to_s}/CCardano.binaries.zip", :sha256 => '08fcaf9e09b9c53a1823cc6131ed2d9b55f6ba595e4fd39cee7f77a51973921a' }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_versions = ['5']
  
  s.vendored_frameworks = "CCardano.xcframework"
end
