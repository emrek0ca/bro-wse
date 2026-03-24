#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SearchEngine) {
    SearchEngineGoogle = 0,
    SearchEngineDuckDuckGo,
    SearchEngineBing
};

@interface SettingsManager : NSObject

@property (copy, nonatomic) NSString *homepage;
@property (assign, nonatomic) SearchEngine searchEngine;
@property (assign, nonatomic) BOOL restoreSessionOnLaunch;

+ (instancetype)sharedManager;
- (NSString *)searchURLForQuery:(NSString *)query;

@end
