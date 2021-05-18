#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run pod lib lint 'chabokpush.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'chabokpush_flutter'
  s.version          = '3.0.0'
  s.summary          = 'Chabok flutter plugin.'
  s.description      = <<-DESC
Chabok provides your app with in-app messaging and easy geo-location features.

Chabok co
                       DESC
  s.homepage         = 'http://chabok.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chabok Realtime Solutions' => 'info@chabok.io' }
  s.source           = { :path => '.' }

  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency "ChabokPush", "~> 2.4.0"

  s.platform = :ios, '8.0'
  s.static_framework = true


end
