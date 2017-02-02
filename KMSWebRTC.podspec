Pod::Spec.new do |s|
  s.name             = "KMSWebRTC"
  s.version          = "1.1.2"
  s.summary          = "Kurento Media Server iOS Web RTC Call."
  s.homepage         = "https://github.com/sdkdimon/kms-ios-webrtc-call"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Dmitry Lizin" => "sdkdimon@gmail.com" }
  s.source           = { :git => "https://github.com/sdkdimon/kms-ios-webrtc-call.git", :tag => s.version }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  s.module_name = 'KMSWebRTC'
  s.source_files = 'KMSWebRTC/KMSWebRTC/*.{h,m}'
  s.dependency 'KMSClient', '1.1.0'
  s.dependency 'ReactiveCocoa', '2.5'
  s.dependency 'WebRTC', '54.6.13869'

end
