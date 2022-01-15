#import "EffektioFlutterSdkPlugin.h"
#if __has_include(<effektio_flutter_sdk/effektio_flutter_sdk-Swift.h>)
#import <effektio_flutter_sdk/effektio_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "effektio_flutter_sdk-Swift.h"
#endif

@implementation EffektioFlutterSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEffektioFlutterSdkPlugin registerWithRegistrar:registrar];
}
@end
