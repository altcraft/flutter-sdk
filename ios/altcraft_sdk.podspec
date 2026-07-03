Pod::Spec.new do |s|
  s.name             = 'altcraft_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Flutter SDK for Altcraft push notification platform'
  s.description      = 'Flutter plugin that bridges the native Altcraft SDK for push notifications on iOS.'
  s.homepage         = 'https://github.com/altcraft/altcraft-sdk-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Altcraft' => 'support@altcraft.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Altcraft', '1.0.3'
  s.platform = :ios, '13.0'
  s.swift_version = '6.0'
  s.pod_target_xcconfig = {
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'SWIFT_STRICT_CONCURRENCY' => 'Disabled'
  }
end
