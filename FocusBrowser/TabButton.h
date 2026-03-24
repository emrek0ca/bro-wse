#import <Cocoa/Cocoa.h>

@interface TabButton : NSView

@property(copy, nonatomic) NSString *title;
@property(assign, nonatomic) BOOL isSelected;
@property(copy, nonatomic) void (^onSelect)(void);
@property(copy, nonatomic) void (^onClose)(void);

- (void)updateAppearance;

@end
