#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint chabokpush.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'chabokpush'
  s.version          = '1.0.0'
  s.summary          = 'Chabok flutter plugin.'
  s.description      = <<-DESC
Chabok flutter plugin.
                       DESC
  s.homepage         = 'http://chabok.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chabok Realtime Solutions' => 'info@chabok.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency "ChabokPush", "~> 2.2.0"
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
