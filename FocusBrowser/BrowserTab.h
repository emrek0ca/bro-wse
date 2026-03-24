#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface BrowserTab : NSObject

@property(strong, nonatomic, readonly) WKWebView *webView;
@property(copy, nonatomic, readonly) NSString *title;
@property(copy, nonatomic) void (^titleChangeHandler)(NSString *);
@property(copy, nonatomic) void (^urlChangeHandler)(NSString *);
@property(copy, nonatomic) void (^progressHandler)(double);
@property(copy, nonatomic) void (^completionHandler)(void);

@property(assign, nonatomic, readonly) BOOL isSuspended;
@property(strong, nonatomic, readonly) NSURL *currentURL;

- (instancetype)initWithURLString:(nullable NSString *)urlString;
- (void)loadURL:(NSURL *)url;
- (void)suspend;
- (void)resume;

@end
