#import <Cocoa/Cocoa.h>

@interface BookmarksWindowController : NSWindowController

@property (copy, nonatomic) void (^onBookmarkSelected)(NSString *url);

@end
