#import "FocusStats.h"

static NSString * const kStatsKey = @"FocusBrowser_DailyStats";

@implementation DailyStats

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _date = [DailyStats todayString];
        _focusMinutes = 0;
        _pomodorosCompleted = 0;
        _sitesBlocked = 0;
        _pagesVisited = 0;
        _focusScore = 0;
    }
    return self;
}

+ (NSString *)todayString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter stringFromDate:[NSDate date]];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _date = [coder decodeObjectOfClass:[NSString class] forKey:@"date"];
        _focusMinutes = [coder decodeIntegerForKey:@"focusMinutes"];
        _pomodorosCompleted = [coder decodeIntegerForKey:@"pomodorosCompleted"];
        _sitesBlocked = [coder decodeIntegerForKey:@"sitesBlocked"];
        _pagesVisited = [coder decodeIntegerForKey:@"pagesVisited"];
        _focusScore = [coder decodeDoubleForKey:@"focusScore"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeInteger:self.focusMinutes forKey:@"focusMinutes"];
    [coder encodeInteger:self.pomodorosCompleted forKey:@"pomodorosCompleted"];
    [coder encodeInteger:self.sitesBlocked forKey:@"sitesBlocked"];
    [coder encodeInteger:self.pagesVisited forKey:@"pagesVisited"];
    [coder encodeDouble:self.focusScore forKey:@"focusScore"];
}

@end

@interface FocusStats ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, DailyStats *> *statsDict;

@end

@implementation FocusStats

+ (instancetype)sharedStats {
    static FocusStats *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FocusStats alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadStats];
    }
    return self;
}

- (void)loadStats {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kStatsKey];
    if (data) {
        NSSet *classes = [NSSet setWithObjects:[NSMutableDictionary class], [NSString class], [DailyStats class], nil];
        NSError *error = nil;
        NSMutableDictionary *loaded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        if (loaded) {
            self.statsDict = loaded;
        } else {
            self.statsDict = [NSMutableDictionary dictionary];
        }
    } else {
        self.statsDict = [NSMutableDictionary dictionary];
    }
}

- (void)saveStats {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.statsDict requiringSecureCoding:YES error:&error];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kStatsKey];
    }
}

- (DailyStats *)todayStats {
    NSString *today = [DailyStats todayString];
    DailyStats *stats = self.statsDict[today];

    if (!stats) {
        stats = [[DailyStats alloc] init];
        self.statsDict[today] = stats;
    }

    return stats;
}

- (NSArray<DailyStats *> *)weeklyStats {
    NSMutableArray *result = [NSMutableArray array];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";

    for (NSInteger i = 6; i >= 0; i--) {
        NSDate *date = [[NSDate date] dateByAddingTimeInterval:-i * 24 * 60 * 60];
        NSString *dateStr = [formatter stringFromDate:date];
        DailyStats *stats = self.statsDict[dateStr];

        if (stats) {
            [result addObject:stats];
        } else {
            DailyStats *empty = [[DailyStats alloc] init];
            empty.date = dateStr;
            [result addObject:empty];
        }
    }

    return result;
}

- (void)addFocusMinutes:(NSInteger)minutes {
    [self todayStats].focusMinutes += minutes;
    [self saveStats];
}

- (void)incrementPomodoros {
    [self todayStats].pomodorosCompleted++;
    [self saveStats];
}

- (void)incrementBlockedSites {
    [self todayStats].sitesBlocked++;
    [self saveStats];
}

- (void)incrementPagesVisited {
    [self todayStats].pagesVisited++;
    [self saveStats];
}

- (void)recordSiteVisit:(NSString *)domain duration:(NSInteger)seconds {
    [self incrementPagesVisited];
}

- (CGFloat)calculateFocusScore {
    DailyStats *today = [self todayStats];

    // Focus score algorithm:
    // - Each pomodoro = 20 points (max 100 from 5 pomodoros)
    // - Each blocked site attempt = 5 points (max 25)
    // - Focus time bonus: 1 point per 5 minutes (max 25)

    CGFloat pomodoroScore = MIN(today.pomodorosCompleted * 20, 100);
    CGFloat blockScore = MIN(today.sitesBlocked * 5, 25);
    CGFloat timeScore = MIN(today.focusMinutes / 5, 25);

    CGFloat total = (pomodoroScore + blockScore + timeScore) / 1.5; // Normalize to 100
    today.focusScore = MIN(total, 100);

    [self saveStats];

    return today.focusScore;
}

- (NSString *)focusScoreDescription {
    CGFloat score = [self calculateFocusScore];

    if (score >= 90) return @"Exceptional Focus!";
    if (score >= 75) return @"Great Progress!";
    if (score >= 50) return @"Good Effort!";
    if (score >= 25) return @"Getting Started";
    return @"Ready to Focus?";
}

@end
