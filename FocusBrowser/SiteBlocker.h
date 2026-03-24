#import <Foundation/Foundation.h>

@interface SiteBlocker : NSObject

@property (assign, nonatomic) BOOL isEnabled;
@property (strong, nonatomic, readonly) NSArray<NSString *> *blockedDomains;

+ (instancetype)sharedBlocker;

- (void)addBlockedDomain:(NSString *)domain;
- (void)removeBlockedDomain:(NSString *)domain;
- (BOOL)shouldBlockURL:(NSURL *)url;
- (void)enableDuringFocusSession:(BOOL)enable;

@end
