#
# Be sure to run `pod lib lint SIAPPay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SIAPPay'
  s.version          = '0.1.0'
  s.summary          = '私有内购控件.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC


  $lib = ENV['use_lib']
  s.homepage         = 'https://github.com/angelcs1990/SIAPPay'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cs' => 'angelcs1990@sohu.com' }
  s.source           = { :git => 'https://github.com/angelcs1990/SIAPPay.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  if $lib
    puts '---------binary-------'
    # s.public_header_files = 'DFCQRCode-0.1.1/ios/DFCQRCode.embeddedframework/DFCQRCode.framework/Versions/A/Headers/*.h'
    s.ios.vendored_framework = "#{s.name}-#{s.version}/ios/#{s.name}.framework"
    # s.xcconfig = { "LIBRARY_SEARCH_PATHS": "\"$(PODS_ROOT)/DFCQRCode/**\"" }
  else
    puts '.......source........'
    s.source_files = "#{s.name}/Classes/**/*"
    s.public_header_files = "#{s.name}/Classes/**/*.h"
  end

  # 设置缓存里即有源码又有.framework
  s.preserve_paths = "#{s.name}/Classes/**/*","#{s.name}-#{s.version}/ios/#{s.name}.framework"

  s.frameworks = 'UIKit', 'StoreKit'
end
