Pod::Spec.new do |s|
  s.name             = 'Cardano-Binaries'
  s.version          = '0.1.4'
  s.summary          = 'Compiled Rust files for Cardano.swift.'

  s.homepage         = 'https://github.com/tesseract-one/Cardano.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "https://github.com/tesseract-one/Cardano.swift/releases/download/#{s.version.to_s}/CCardano.binaries.zip", :sha256 => '226023203151474e6c3788ef1c3acd677ac5f4b76dffab65080d280e8a2c37ee' }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  # s.tvos.deployment_target = '11.0'
  
  s.swift_version = '5.4'
  
  s.module_name = 'CCardano'
  
  s.vendored_frameworks = 'CCardano.xcframework'
end
