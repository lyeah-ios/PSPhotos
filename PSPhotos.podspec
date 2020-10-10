#
# Be sure to run `pod lib lint PSPhotos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PSPhotos'
  s.version          = '0.2.0'
  s.summary          = 'PSPhotos makes it easier to use Photos.framework to read and store images or videos.'

  s.homepage         = 'https://github.com/zisulu/PSPhotos'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zisu' => 'zisulwl@163.com' }
  s.source           = { :git => 'https://github.com/zisulu/PSPhotos.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.requires_arc     = true
  s.frameworks       = 'Foundation', 'UIKit'
  s.default_subspec  = 'Photos'
  
  # Photos
  s.subspec 'Photos' do |ss|
    ss.source_files = 'PSPhotos/Photos/*.{h,m}'
    ss.frameworks = 'Photos', 'CoreServices'
    
  end
  
  # AVFoundation/MediaPlayer
  s.subspec 'AVMedia' do |ss|
    ss.source_files = 'PSPhotos/AVFoundation/*.{h,m}'
    
    ss.dependency 'PSPhotos/Photos'
    ss.frameworks = 'AVFoundation', 'MediaPlayer'
    
  end
  
end
