#
# Be sure to run `pod lib lint PSPhotos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PSPhotos'
  s.version          = '0.1.0'
  s.summary          = 'PSPhotos makes it easier to use Photos.framework to read and store images or videos.'

  s.homepage         = 'https://github.com/lyeah-ios/PSPhotos'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zisu' => 'zisulwl@163.com' }
  s.source           = { :git => 'https://github.com/lyeah-ios/PSPhotos.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'PSPhotos/Classes/**/*'

  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'Photos', 'CoreServices'
end
