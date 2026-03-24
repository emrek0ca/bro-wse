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
        @try {
            NSError *error;
            NSSet *classes = [NSSet setWithArray:@[[NSArray class], [HistoryItem class], [NSDate class]]];
            NSArray *items = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
            if (error) {
                NSLog(@"HistoryManager: Failed to unarchive history: %@", error);
                _mutableHistory = [NSMutableArray array];
            } else {
                _mutableHistory = [items mutableCopy] ?: [NSMutableArray array];
            }
        } @catch (NSException *exception) {
            NSLog(@"HistoryManager: Exception during history recovery: %@", exception);
            _mutableHistory = [NSMutableArray array];
        }
    } else {
        _mutableHistory = [NSMutableArray array];
    }
}

- (void)saveHistory {
    @synchronized (self) {
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.mutableHistory requiringSecureCoding:YES error:&error];
        if (data) {
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:kHistoryItemsKey];
        } else if (error) {
            NSLog(@"HistoryManager: Failed to archive history: %@", error);
        }
    }
}

- (void)addHistoryItemWithTitle:(NSString *)title urlString:(NSString *)urlString {
    if (!urlString || urlString.length == 0 || [urlString hasPrefix:@"focus://"]) return;
    
    @synchronized (self) {
        HistoryItem *item = [[HistoryItem alloc] init];
        item.title = title ?: urlString;
        item.urlString = urlString;
        item.timestamp = [NSDate date];
        
        // Remove existing to bring to top if it's a "move to front" logic, 
        // or just check last for "don't duplicate consecutive"
        if (self.mutableHistory.count > 0) {
            HistoryItem *last = self.mutableHistory.firstObject;
            if ([last.urlString isEqualToString:urlString]) {
                last.timestamp = item.timestamp; // Update time
                // No need to add new, just notify or save
                [self saveHistory];
                return;
            }
        }
        
        [self.mutableHistory insertObject:item atIndex:0];
        
        if (self.mutableHistory.count > 500) { // Reduced limit for performance
            [self.mutableHistory removeLastObject];
        }
        
        [self saveHistory];
    }
}

- (NSArray<HistoryItem *> *)allHistory {
    return [self.mutableHistory copy];
}

- (void)clearHistory {
    [self.mutableHistory removeAllObjects];
    [self saveHistory];
}

@end
