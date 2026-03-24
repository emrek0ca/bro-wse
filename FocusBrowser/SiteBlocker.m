#import "SiteBlocker.h"

static NSString * const kBlockedDomainsKey = @"FocusBrowser_BlockedDomains";
static NSString * const kBlockerEnabledKey = @"FocusBrowser_BlockerEnabled";

@interface SiteBlocker ()

@property (strong, nonatomic) NSMutableArray<NSString *> *mutableBlockedDomains;

@end

@implementation SiteBlocker

+ (instancetype)sharedBlocker {
    static SiteBlocker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SiteBlocker alloc] init];
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
    NSArray *saved = [defaults arrayForKey:kBlockedDomainsKey];

    if (saved) {
        _mutableBlockedDomains = [saved mutableCopy];
    } else {
        // Default distracting sites
        _mutableBlockedDomains = [@[
            @"facebook.com",
            @"twitter.com",
            @"x.com",
            @"instagram.com",
            @"tiktok.com",
            @"reddit.com",
            @"youtube.com",
            @"netflix.com",
            @"twitch.tv"
        ] mutableCopy];
        [self saveSettings];
    }

    _isEnabled = [defaults boolForKey:kBlockerEnabledKey];
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.mutableBlockedDomains forKey:kBlockedDomainsKey];
    [defaults setBool:self.isEnabled forKey:kBlockerEnabledKey];
}

- (NSArray<NSString *> *)blockedDomains {
    return [self.mutableBlockedDomains copy];
}

- (void)addBlockedDomain:(NSString *)domain {
    NSString *cleanDomain = [domain lowercaseString];
    cleanDomain = [cleanDomain stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    cleanDomain = [cleanDomain stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    cleanDomain = [cleanDomain stringByReplacingOccurrencesOfString:@"www." withString:@""];

    if (![self.mutableBlockedDomains containsObject:cleanDomain]) {
        [self.mutableBlockedDomains addObject:cleanDomain];
        [self saveSettings];
    }
}

- (void)removeBlockedDomain:(NSString *)domain {
    [self.mutableBlockedDomains removeObject:domain];
    [self saveSettings];
}

- (void)setIsEnabled:(BOOL)isEnabled {
    _isEnabled = isEnabled;
    [self saveSettings];
}

- (BOOL)shouldBlockURL:(NSURL *)url {
    if (!self.isEnabled) return NO;
    if (!url.host) return NO;

    NSString *host = [url.host lowercaseString];
    if ([host hasPrefix:@"www."]) {
        host = [host substringFromIndex:4];
    }

    for (NSString *blocked in self.mutableBlockedDomains) {
        NSString *cleanBlocked = [blocked lowercaseString];
        // Match exact host or suffix (e.g., mail.google.com matches google.com)
        if ([host isEqualToString:cleanBlocked] || [host hasSuffix:[NSString stringWithFormat:@".%@", cleanBlocked]]) {
            return YES;
        }
    }

    return NO;
}

- (void)enableDuringFocusSession:(BOOL)enable {
    self.isEnabled = enable;
}

@end
