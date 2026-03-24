#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController

- (void)createNewTabWithURL:(NSString *)urlString;
- (void)restoreTabsWithURLs:(NSArray<NSString *> *)urls;
- (NSArray<NSString *> *)allTabURLs;
- (void)navigateToURL:(NSString *)urlString;

@end
