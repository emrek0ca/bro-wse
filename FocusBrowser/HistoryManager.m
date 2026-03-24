#import "HistoryManager.h"

@implementation HistoryItem

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.urlString forKey:@"urlString"];
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _urlString = [coder decodeObjectOfClass:[NSString class] forKey:@"urlString"];
        _timestamp = [coder decodeObjectOfClass:[NSDate class] forKey:@"timestamp"];
    }
    return self;
}

@end

static NSString * const kHistoryItemsKey = @"FocusBrowser_HistoryItems";

@interface HistoryManager ()
@property (strong, nonatomic) NSMutableArray<HistoryItem *> *mutableHistory;
@end

@implementation HistoryManager

+ (instancetype)sharedManager {
    static HistoryManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HistoryManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadHistory];
    }
    return self;
}

- (void)loadHistory {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kHistoryItemsKey];
    if (data) {
        NSError *error;
        NSSet *classes = [NSSet setWithArray:@[[NSArray class], [HistoryItem class]]];
        NSArray *items = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        _mutableHistory = [items mutableCopy] ?: [NSMutableArray array];
    } else {
        _mutableHistory = [NSMutableArray array];
    }
}

- (void)saveHistory {
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.mutableHistory requiringSecureCoding:YES error:&error];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kHistoryItemsKey];
    }
}

- (void)addHistoryItemWithTitle:(NSString *)title urlString:(NSString *)urlString {
    if ([urlString hasPrefix:@"focus://"]) return; // Don't record internal pages
    
    HistoryItem *item = [[HistoryItem alloc] init];
    item.title = title ?: urlString;
    item.urlString = urlString;
    item.timestamp = [NSDate date];
    
    // Check if same as last to avoid duplicates
    if (self.mutableHistory.count > 0) {
        HistoryItem *last = self.mutableHistory.firstObject;
        if ([last.urlString isEqualToString:urlString]) {
            last.timestamp = [NSDate date]; // Just update time
            [self.mutableHistory removeObjectAtIndex:0];
            [self.mutableHistory insertObject:last atIndex:0];
            [self saveHistory];
            return;
        }
    }
    
    [self.mutableHistory insertObject:item atIndex:0];
    
    // Limit history to 1000 items
    if (self.mutableHistory.count > 1000) {
        [self.mutableHistory removeLastObject];
    }
    
    [self saveHistory];
}

- (NSArray<HistoryItem *> *)allHistory {
    return [self.mutableHistory copy];
}

- (void)clearHistory {
    [self.mutableHistory removeAllObjects];
    [self saveHistory];
}

@end
