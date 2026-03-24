#import <Cocoa/Cocoa.h>

@interface ModernTabButton : NSView

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *urlHost;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL isLoading;
@property (strong, nonatomic) NSImage *favicon;

@property (copy, nonatomic) void (^onSelect)(void);
@property (copy, nonatomic) void (^onClose)(void);

@end
