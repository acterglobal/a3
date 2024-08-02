#import "ActerFlutterSdkPlugin.h"
#if __has_include(<acter_flutter_sdk/acter_flutter_sdk-Swift.h>)
#import <acter_flutter_sdk/acter_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "acter_flutter_sdk-Swift.h"
#endif

@implementation ActerFlutterSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftActerFlutterSdkPlugin registerWithRegistrar:registrar];
}
@end
