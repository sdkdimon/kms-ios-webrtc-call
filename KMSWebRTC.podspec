Pod::Spec.new do |s|
  s.name             = "KMSWebRTC"
  s.version          = "1.1.3"
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
  s.dependency 'KMSClient', '1.1.1'
  s.dependency 'ReactiveObjC', '2.1.2'
  s.dependency 'WebRTC', '57.2.16123'

end
