#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface DownloadManager : NSObject

@property(nonatomic, strong, readonly)
    NSMutableArray *downloads; // Array of NSDictionaries or custom objects

+ (instancetype)sharedManager;
- (void)addDownload:(WKDownload *)download;

@end
