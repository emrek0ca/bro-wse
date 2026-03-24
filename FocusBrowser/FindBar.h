#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface FindBar : NSView

@property (weak, nonatomic) WKWebView *webView;
@property (copy, nonatomic) void (^onClose)(void);

- (void)show;
- (void)hide;
- (void)focus;

@end
