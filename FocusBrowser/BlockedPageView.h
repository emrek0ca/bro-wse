#import <Cocoa/Cocoa.h>

@interface BlockedPageView : NSView

@property (copy, nonatomic) NSString *blockedDomain;
@property (copy, nonatomic) void (^onGoBack)(void);
@property (copy, nonatomic) void (^onAllowOnce)(void);

@end
