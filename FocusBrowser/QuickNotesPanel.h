#import <Cocoa/Cocoa.h>

@interface QuickNotesPanel : NSView

@property (copy, nonatomic) void (^onClose)(void);

- (void)show;
- (void)hide;
- (void)toggle;
- (BOOL)isVisible;

@end
