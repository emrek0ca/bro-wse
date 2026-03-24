#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface BrowserTab : NSObject

@property(strong, nonatomic, readonly) WKWebView *webView;
@property(copy, nonatomic, readonly) NSString *title;
@property(copy, nonatomic) void (^urlChangeHandler)(NSString *newURL);
@property(copy, nonatomic) void (^titleChangeHandler)(NSString *newTitle);
@property(copy, nonatomic) void (^progressHandler)(double progress);
@property(copy, nonatomic) void (^completionHandler)(void);

- (instancetype)initWithURLString:(NSString *)urlString;
- (void)loadURL:(NSURL *)url;

@end
