Pod::Spec.new do |s|
  s.name = "SIAPPay"
  s.version = "0.1.0"
  s.summary = "\u{79c1}\u{6709}\u{5185}\u{8d2d}\u{63a7}\u{4ef6}."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"cs"=>"angelcs1990@sohu.com"}
  s.homepage = "https://github.com/angelcs1990/SIAPPay"
  s.description = "TODO: Add long description of the pod here."
  s.frameworks = ["UIKit", "StoreKit"]
  s.source = { :path => '.' }

  s.ios.deployment_target    = '8.0'
  s.ios.vendored_framework   = 'ios/SIAPPay.framework'
end
