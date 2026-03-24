#import "SessionManager.h"

static NSString * const kSessionURLsKey = @"FocusBrowser_SessionURLs";

@implementation SessionManager

+ (instancetype)sharedManager {
    static SessionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SessionManager alloc] init];
    });
    return instance;
}

- (void)saveSession:(NSArray<NSString *> *)urls {
    [[NSUserDefaults standardUserDefaults] setObject:urls forKey:kSessionURLsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<NSString *> *)restoreSession {
    NSArray *urls = [[NSUserDefaults standardUserDefaults] arrayForKey:kSessionURLsKey];
    return urls ?: @[];
}

@end
