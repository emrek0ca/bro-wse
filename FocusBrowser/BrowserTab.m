#import "BrowserTab.h"
#import "AdBlockManager.h"
#import "DownloadManager.h"

@interface BrowserTab () <WKNavigationDelegate, WKUIDelegate>

@property(strong, nonatomic, readwrite) WKWebView *webView;
@property(copy, nonatomic, readwrite) NSString *title;

@end

@implementation BrowserTab

- (instancetype)initWithURLString:(NSString *)urlString {
  self = [super init];
  if (self) {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    // Performance & Privacy Optimizations
    config.allowsAirPlayForMediaPlayback = NO;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;

    if (@available(macOS 12.0, *)) {
        config.allowsStreamingMediaAutoplay = NO;
    }

    // Ad Blocking
    [[AdBlockManager sharedManager]
        compileRulesWithCompletion:^(WKContentRuleList *ruleList) {
          if (ruleList) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [config.userContentController addContentRuleList:ruleList];
              NSLog(@"AdBlock rules applied.");
            });
          }
        }];

    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect
                                  configuration:config];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    _webView.allowsBackForwardNavigationGestures = YES;

    // UI Performance
    if (@available(macOS 12.0, *)) {
        _webView.underPageBackgroundColor = [[ThemeManager sharedManager] backgroundColor];
    }

    _title = @"New Tab";

    [_webView addObserver:self
               forKeyPath:@"title"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [_webView addObserver:self
               forKeyPath:@"URL"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [_webView addObserver:self
               forKeyPath:@"estimatedProgress"
                  options:NSKeyValueObservingOptionNew
                  context:nil];

    if (urlString) {
      NSURL *url = [NSURL URLWithString:urlString];
      if (url) {
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
      }
    }
  }
  return self;
}

- (void)dealloc {
  @try {
    [_webView removeObserver:self forKeyPath:@"title"];
    [_webView removeObserver:self forKeyPath:@"URL"];
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
  } @catch (NSException *exception) {
  }
}

- (void)loadURL:(NSURL *)url {
  [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"title"]) {
    self.title = self.webView.title ?: @"New Tab";
    if (self.titleChangeHandler) {
      self.titleChangeHandler(self.title);
    }
  } else if ([keyPath isEqualToString:@"URL"]) {
    if (self.urlChangeHandler) {
      self.urlChangeHandler(self.webView.URL.absoluteString);
    }
  } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
    if (self.progressHandler) {
      self.progressHandler(self.webView.estimatedProgress);
    }
  }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView
    didStartProvisionalNavigation:(WKNavigation *)navigation {
  if (self.progressHandler) {
    self.progressHandler(0.1);
  }
}

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  if (self.progressHandler) {
    self.progressHandler(1.0);
  }
  if (self.completionHandler) {
    self.completionHandler();
  }
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
  if (self.progressHandler) {
    self.progressHandler(1.0);
  }
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
  if (error.code == NSURLErrorCancelled)
    return;
  if (self.progressHandler) {
    self.progressHandler(1.0);
  }
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
               forNavigationAction:(WKNavigationAction *)navigationAction
                    windowFeatures:(WKWindowFeatures *)windowFeatures {
  if (navigationAction.targetFrame == nil) {
    [webView loadRequest:navigationAction.request];
  }
  return nil;
}

#pragma mark - WKDownloadDelegate

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))
                                          decisionHandler {
  if (navigationResponse.canShowMIMEType) {
    decisionHandler(WKNavigationResponsePolicyAllow);
  } else {
    decisionHandler(WKNavigationResponsePolicyDownload);
  }
}

- (void)webView:(WKWebView *)webView
     navigationAction:(WKNavigationAction *)navigationAction
    didBecomeDownload:(WKDownload *)download {
  [[DownloadManager sharedManager] addDownload:download];
}

- (void)webView:(WKWebView *)webView
    navigationResponse:(WKNavigationResponse *)navigationResponse
     didBecomeDownload:(WKDownload *)download {
  [[DownloadManager sharedManager] addDownload:download];
}

@end
