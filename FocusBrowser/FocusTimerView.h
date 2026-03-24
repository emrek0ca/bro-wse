#import <Cocoa/Cocoa.h>

@interface FocusTimerView : NSView

@property(assign, nonatomic) CGFloat progress; // 0.0 to 1.0
@property(strong, nonatomic) NSColor *progressColor;
@property(assign, nonatomic) CGFloat strokeWidth;
@property(strong, nonatomic) NSString *timeString;

- (void)startPulseAnimation;
- (void)stopPulseAnimation;

@end
