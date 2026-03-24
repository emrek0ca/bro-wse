#import "FocusSessionManager.h"
#import "SiteBlocker.h"
#import "FocusStats.h"

static NSString * const kSessionHistoryKey = @"FocusBrowser_SessionHistory";

@implementation FocusSession

+ (BOOL)supportsSecureCoding { return YES; }

+ (instancetype)sessionWithName:(NSString *)name duration:(NSInteger)minutes {
    FocusSession *session = [[FocusSession alloc] init];
    session.identifier = [[NSUUID UUID] UUIDString];
    session.name = name;
    session.durationMinutes = minutes;
    session.blockSites = YES;
    session.strictMode = NO;
    return session;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _identifier = [coder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _durationMinutes = [coder decodeIntegerForKey:@"durationMinutes"];
        _blockSites = [coder decodeBoolForKey:@"blockSites"];
        _strictMode = [coder decodeBoolForKey:@"strictMode"];
        _startTime = [coder decodeObjectOfClass:[NSDate class] forKey:@"startTime"];
        _endTime = [coder decodeObjectOfClass:[NSDate class] forKey:@"endTime"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInteger:self.durationMinutes forKey:@"durationMinutes"];
    [coder encodeBool:self.blockSites forKey:@"blockSites"];
    [coder encodeBool:self.strictMode forKey:@"strictMode"];
    [coder encodeObject:self.startTime forKey:@"startTime"];
    [coder encodeObject:self.endTime forKey:@"endTime"];
}

@end

@interface FocusSessionManager ()

@property (strong, nonatomic, readwrite) FocusSession *activeSession;
@property (assign, nonatomic, readwrite) NSInteger remainingSeconds;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray<FocusSession *> *history;

@end

@implementation FocusSessionManager

+ (instancetype)sharedManager {
    static FocusSessionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FocusSessionManager alloc] init];
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

- (BOOL)isSessionActive {
    return self.activeSession != nil;
}

- (void)loadHistory {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kSessionHistoryKey];
    if (data) {
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class], [FocusSession class], nil];
        NSError *error = nil;
        NSMutableArray *loaded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        self.history = loaded ?: [NSMutableArray array];
    } else {
        self.history = [NSMutableArray array];
    }
}

- (void)saveHistory {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.history requiringSecureCoding:YES error:&error];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kSessionHistoryKey];
    }
}

- (void)startSession:(FocusSession *)session {
    if (self.isSessionActive) {
        [self endSession];
    }

    self.activeSession = session;
    session.startTime = [NSDate date];
    self.remainingSeconds = session.durationMinutes * 60;

    if (session.blockSites) {
        [[SiteBlocker sharedBlocker] setIsEnabled:YES];
    }

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

    if (self.onSessionStart) {
        self.onSessionStart(session);
    }
}

- (void)tick {
    self.remainingSeconds--;

    if (self.onTick) {
        self.onTick(self.remainingSeconds);
    }

    if (self.remainingSeconds <= 0) {
        [self endSession];
    }
}

- (void)endSession {
    [self.timer invalidate];
    self.timer = nil;

    if (self.activeSession) {
        self.activeSession.endTime = [NSDate date];

        NSInteger actualMinutes = (NSInteger)([self.activeSession.endTime timeIntervalSinceDate:self.activeSession.startTime] / 60);
        [[FocusStats sharedStats] addFocusMinutes:actualMinutes];

        [self.history insertObject:self.activeSession atIndex:0];
        if (self.history.count > 100) {
            [self.history removeLastObject];
        }
        [self saveHistory];

        if (self.onSessionEnd) {
            self.onSessionEnd(self.activeSession);
        }

        self.activeSession = nil;
    }

    self.remainingSeconds = 0;
}

- (NSArray<FocusSession *> *)sessionHistory {
    return [self.history copy];
}

- (NSArray<FocusSession *> *)presetSessions {
    return @[
        [FocusSession sessionWithName:@"Quick Focus" duration:15],
        [FocusSession sessionWithName:@"Standard" duration:25],
        [FocusSession sessionWithName:@"Deep Work" duration:50],
        [FocusSession sessionWithName:@"Marathon" duration:90],
    ];
}

- (NSInteger)todayFocusMinutes {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    NSInteger total = 0;

    for (FocusSession *session in self.history) {
        if (session.endTime && [calendar isDate:session.endTime inSameDayAsDate:today]) {
            total += (NSInteger)([session.endTime timeIntervalSinceDate:session.startTime] / 60);
        }
    }

    return total;
}

@end
