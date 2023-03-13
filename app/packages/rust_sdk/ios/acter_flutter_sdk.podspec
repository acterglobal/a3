#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint acter_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'acter_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://acter.global'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Acter' => 'team@acter.global' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
