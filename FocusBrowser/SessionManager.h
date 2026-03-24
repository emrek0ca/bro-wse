#import <Foundation/Foundation.h>

@interface SessionManager : NSObject

+ (instancetype)sharedManager;
- (void)saveSession:(NSArray<NSString *> *)urls;
- (NSArray<NSString *> *)restoreSession;

@end
