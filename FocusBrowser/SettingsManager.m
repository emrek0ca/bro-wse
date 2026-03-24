#import "SettingsManager.h"

static NSString * const kHomepageKey = @"FocusBrowser_Homepage";
static NSString * const kSearchEngineKey = @"FocusBrowser_SearchEngine";
static NSString * const kRestoreSessionKey = @"FocusBrowser_RestoreSession";

@implementation SettingsManager

+ (instancetype)sharedManager {
    static SettingsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SettingsManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadSettings];
    }
    return self;
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    _homepage = [defaults stringForKey:kHomepageKey] ?: @"focus://start";
    _searchEngine = [defaults integerForKey:kSearchEngineKey];
    _restoreSessionOnLaunch = [defaults objectForKey:kRestoreSessionKey] ? [defaults boolForKey:kRestoreSessionKey] : YES;
}

- (void)setHomepage:(NSString *)homepage {
    _homepage = homepage;
    [[NSUserDefaults standardUserDefaults] setObject:homepage forKey:kHomepageKey];
}

- (void)setSearchEngine:(SearchEngine)searchEngine {
    _searchEngine = searchEngine;
    [[NSUserDefaults standardUserDefaults] setInteger:searchEngine forKey:kSearchEngineKey];
}

- (void)setRestoreSessionOnLaunch:(BOOL)restoreSessionOnLaunch {
    _restoreSessionOnLaunch = restoreSessionOnLaunch;
    [[NSUserDefaults standardUserDefaults] setBool:restoreSessionOnLaunch forKey:kRestoreSessionKey];
}

- (NSString *)searchURLForQuery:(NSString *)query {
    NSString *encoded = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    switch (self.searchEngine) {
        case SearchEngineGoogle:
            return [NSString stringWithFormat:@"https://www.google.com/search?q=%@", encoded];
        case SearchEngineDuckDuckGo:
            return [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@", encoded];
        case SearchEngineBing:
            return [NSString stringWithFormat:@"https://www.bing.com/search?q=%@", encoded];
    }
    return [NSString stringWithFormat:@"https://www.google.com/search?q=%@", encoded];
}

@end
