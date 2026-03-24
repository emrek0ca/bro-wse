#import "BrowserTab.h"
#import "AdBlockManager.h"
#import "DownloadManager.h"
#import "HistoryManager.h"

@interface BrowserTab () <WKNavigationDelegate, WKUIDelegate>

@property(strong, nonatomic, readwrite) WKWebView *webView;
@property(copy, nonatomic, readwrite) NSString *title;
@property(assign, nonatomic, readwrite) BOOL isSuspended;
@property(strong, nonatomic, readwrite) NSURL *currentURL;
@property(strong, nonatomic) NSString *initialURL;

@end

@implementation BrowserTab

- (instancetype)initWithURLString:(NSString *)urlString {
  self = [super init];
  if (self) {
    _initialURL = urlString;
    _title = @"New Tab";
    _isSuspended = NO;
    [self createWebView];
    
    if (urlString) {
      _currentURL = [NSURL URLWithString:urlString];
      if (_currentURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:_currentURL]];
      }
    }
  }
  return self;
}

- (void)createWebView {
  if (_webView) return;

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
            NSLog(@"AdBlock rules applied to new webview.");
          });
        }
      }];

  _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:config];
  _webView.navigationDelegate = self;
  _webView.UIDelegate = self;
  _webView.allowsBackForwardNavigationGestures = YES;

  if (@available(macOS 12.0, *)) {
    _webView.underPageBackgroundColor = [[ThemeManager sharedManager] backgroundColor];
  }

  [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
  [_webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
  [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)suspend {
    if (self.isSuspended || !self.webView) return;
    
    NSLog(@"[BrowserTab] Suspending tab: %@", self.title);
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    
    @try {
        [_webView removeObserver:self forKeyPath:@"title"];
        [_webView removeObserver:self forKeyPath:@"URL"];
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    } @catch (NSException *e) {}
    
    self.webView = nil;
    self.isSuspended = YES;
}

- (void)resume {
    if (!self.isSuspended) return;
    
    NSLog(@"[BrowserTab] Resuming tab: %@", self.title);
    [self createWebView];
    self.isSuspended = NO;
    
    if (self.currentURL) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.currentURL]];
    }
}

- (void)dealloc {
  if (_webView) {
    @try {
        [_webView removeObserver:self forKeyPath:@"title"];
        [_webView removeObserver:self forKeyPath:@"URL"];
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    } @catch (NSException *exception) {}
  }
}

- (void)loadURL:(NSURL *)url {
  self.currentURL = url;
  if (self.isSuspended) {
      [self resume];
  } else {
      [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
  }
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
    if (self.webView.URL) {
        self.currentURL = self.webView.URL;
    }
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
  
  if (webView.title && webView.URL.absoluteString) {
      [[HistoryManager sharedManager] addHistoryItemWithTitle:webView.title
                                                   urlString:webView.URL.absoluteString];
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
