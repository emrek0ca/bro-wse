#import "AppDelegate.h"
#import "MainWindowController.h"
#import "SessionManager.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.mainWindowController = [[MainWindowController alloc] init];
    [self.mainWindowController showWindow:nil];
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    NSArray *urls = [[SessionManager sharedManager] restoreSession];
    if (urls.count > 0) {
        [self.mainWindowController restoreTabsWithURLs:urls];
    } else {
        [self.mainWindowController createNewTabWithURL:@"https://www.apple.com"];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSArray *urls = [self.mainWindowController allTabURLs];
    [[SessionManager sharedManager] saveSession:urls];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
