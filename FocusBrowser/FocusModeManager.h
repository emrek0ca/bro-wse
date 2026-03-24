#import <Foundation/Foundation.h>

@interface FocusModeManager : NSObject

@property (assign, nonatomic, readonly) BOOL isEnabled;
@property (copy, nonatomic) void (^toggleHandler)(BOOL enabled);

+ (instancetype)sharedManager;
- (void)toggle;
- (void)setEnabled:(BOOL)enabled;

@end
