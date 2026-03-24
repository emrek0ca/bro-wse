#import "DownloadManager.h"

@interface DownloadTask : NSObject <WKDownloadDelegate>
@property(strong, nonatomic) WKDownload *download;
@property(strong, nonatomic) NSURL *destinationURL;
@property(assign, nonatomic) double progress;
@property(weak, nonatomic) DownloadManager *manager;
@end

@implementation DownloadTask
// Delegate methods would handle progress here
// For now, minimal impl
- (void)download:(WKDownload *)download
    decideDestinationUsingResponse:(NSURLResponse *)response
                 suggestedFilename:(NSString *)suggestedFilename
                 completionHandler:
                     (void (^)(NSURL *_Nullable))completionHandler {

  NSString *downloadsDir = [NSSearchPathForDirectoriesInDomains(
      NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
  NSURL *destination = [NSURL
      fileURLWithPath:[downloadsDir
                          stringByAppendingPathComponent:suggestedFilename]];
  self.destinationURL = destination;

  NSLog(@"Download starting: %@", destination);
  completionHandler(destination);
}

- (void)downloadDidFinish:(WKDownload *)download {
  NSLog(@"Download finished: %@", self.destinationURL);
  [self.manager removeTask:self];
}

- (void)download:(WKDownload *)download
    didFailWithError:(NSError *)error
          resumeData:(NSData *)resumeData {
  NSLog(@"Download failed: %@", error);
  [self.manager removeTask:self];
}

@end

@implementation DownloadManager

+ (instancetype)sharedManager {
  static DownloadManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] init];
  });
  return shared;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _downloads = [NSMutableArray array];
  }
  return self;
}

- (void)addDownload:(WKDownload *)download {
  DownloadTask *task = [[DownloadTask alloc] init];
  task.download = download;
  task.manager = self;
  download.delegate = task; // Set delegate to our wrapper
  [self.downloads addObject:task];
}

- (void)removeTask:(DownloadTask *)task {
    [self.downloads removeObject:task];
}

@end
