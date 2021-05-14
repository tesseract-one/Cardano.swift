Pod::Spec.new do |s|
  s.name             = 'Cardano-Binaries'
  s.version          = '0.0.1'
  s.summary          = 'Compiled Rust files for Cardano.swift.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "https://github.com/tesseract-one/Cardano.swift/releases/download/#{s.version.to_s}/Cardano.binaries.zip", :sha256 => '' }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_versions = ['5.3', '5.4']
  
  s.vendored_frameworks = "CCardano.xcframework"
end
