@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface SQAAutostart : NSObject

+ (BOOL)isEnabled;
+ (BOOL)enable;
+ (BOOL)disable;
+ (BOOL)isRunningFromReadOnlyLocation;

@end

NS_ASSUME_NONNULL_END
