#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint acter_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'acter_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'flutter bindings for libacter'
  s.description      = <<-DESC
  flutter bindings for libacter
                       DESC
  s.homepage         = 'http://acter.global'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Acter' => 'team@acter.global' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  # s.static_framework = true
  s.platform = :ios, '12.0'
  s.vendored_libraries = "**/*.a"
  s.preserve_paths = "**/*.a"

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    # "HEADER_SEARCH_PATHS" => "$(FRAMEWORK_SEARCH_PATHS)/LibActer.xcframework/Headers",
    # "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
    # 'DEAD_CODE_STRIPPING' => 'NO',
    # 'STRIP_INSTALLED_PRODUCT' => 'NO',
    # 'PRESERVE_DEAD_CODE_INITS_AND_TERMS' => 'NO',
    # 'UNSTRIPPED_PRODUCT' => 'YES',
    # 'OTHER_LDFLAGS' => '-Wl,-force_load,libacter.a ',
    # 'EXPORTED_SYMBOLS_FILE' => "${PROJECT_DIR}/exported_symbols",
    'DEFINES_MODULE' => 'YES',
    # 'KEEP_PRIVATE_EXTERNS' => 'YES',
    # 'STRIP_STYLE' => 'debugging',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
