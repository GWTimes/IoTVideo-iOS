# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

workspace 'IotVideo.xcworkspace'

inhibit_all_warnings!
use_frameworks!

target 'IotVideoDemo' do
  project './Demo/IotVideoDemo/IotVideoDemo.xcodeproj'
  pod 'IQKeyboardManagerSwift', '~> 6.5.0'
  pod 'MBProgressHUD',          '~> 1.1.0'
  pod 'AFNetworking',           '~> 3.0'
  pod 'SwiftyJSON',             '~> 4.0'
  pod 'SDWebImage',             '~> 5.0.0'
  pod 'SnapKit',                '~> 4.2.0'
  pod 'Then',                   '~> 2.4.0'
end

#target 'IoTVideo' do
#  project './SDK/IoTVideo/IoTVideo.xcodeproj'
#end

target 'IVNetwork' do
  project './SDK/IVNetwork/IVNetwork.xcodeproj'
  pod 'AFNetworking', '~> 3.0'
end
