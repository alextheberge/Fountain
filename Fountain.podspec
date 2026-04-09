Pod::Spec.new do |s|
  s.name         = "Fountain"
  s.version      = "1.1.0"
  s.summary      = "An open source implementation of the Fountain screenplay formatting language."
  s.homepage     = "http://fountain.io"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Nima Yousefi" => "inbox@nimayousefi.com" }
  s.source       = { :git => "https://github.com/nyousefi/Fountain.git", :tag => "v#{s.version}" }

  s.source_files   = "Fountain/*.swift"
  s.swift_versions = "5.9"

  s.ios.deployment_target = "15.0"
  s.osx.deployment_target = "12.0"
end
