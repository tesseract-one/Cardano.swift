Pod::Spec.new do |s|
  s.name             = 'Cardano-Binaries'
  s.version          = '0.1.0'
  s.summary          = 'Compiled Rust files for Cardano.swift.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "https://github.com/tesseract-one/Cardano.swift/releases/download/#{s.version.to_s}/Cardano.binaries.zip", :sha256 => '0b9a5e4d768da0edc7fe3834a03d2b463633c64121cc76bc2ec338006a500b77' }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_versions = ['5.3', '5.4', '5.5']
  
  s.vendored_frameworks = "CCardano.xcframework"
end
