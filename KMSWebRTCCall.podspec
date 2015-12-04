Pod::Spec.new do |s|
  s.name             = "KMSWebRTCCall"
  s.version          = "1.0.6"
  s.summary          = "Kurento Media Server iOS Web RTC Call."
  s.homepage         = "https://github.com/sdkdimon/kms-ios-webrtc-call"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Dmitry Lizin" => "sdkdimon@gmail.com" }
  s.source           = { :git => "https://github.com/sdkdimon/kms-ios-webrtc-call.git", :tag => s.version }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.module_name = 'KMSWebRTCCall'
  s.source_files = 'KMSWebRTCCall/*.{h,m}'
  s.dependency 'KMSClient', '1.0.5'
  s.dependency 'ReactiveCocoa', '2.5'
  s.dependency 'WebRTC_framework', '10842.2.3'

end
