#import "PomodoroTimer.h"
#import <UserNotifications/UserNotifications.h>

@interface PomodoroTimer ()

@property (assign, nonatomic, readwrite) PomodoroState state;
@property (assign, nonatomic, readwrite) NSInteger remainingSeconds;
@property (assign, nonatomic, readwrite) NSInteger completedPomodoros;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) PomodoroState stateBeforePause;

@end

@implementation PomodoroTimer

+ (instancetype)sharedTimer {
    static PomodoroTimer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PomodoroTimer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = PomodoroStateIdle;
        _workDuration = 25 * 60;
        _shortBreakDuration = 5 * 60;
        _longBreakDuration = 15 * 60;
        _completedPomodoros = 0;
        [self loadStats];
        [self requestNotificationPermission];
    }
    return self;
}

- (void)requestNotificationPermission {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError *error) {}];
}

- (void)loadStats {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *today = [self todayString];
    NSString *savedDate = [defaults stringForKey:@"FocusBrowser_PomodoroDate"];

    if ([savedDate isEqualToString:today]) {
        _completedPomodoros = [defaults integerForKey:@"FocusBrowser_PomodoroCount"];
    } else {
        _completedPomodoros = 0;
    }
}

- (void)saveStats {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self todayString] forKey:@"FocusBrowser_PomodoroDate"];
    [defaults setInteger:self.completedPomodoros forKey:@"FocusBrowser_PomodoroCount"];
}

- (NSString *)todayString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)start {
    [self.timer invalidate];
    self.state = PomodoroStateWork;
    self.remainingSeconds = self.workDuration;
    [self startTimer];

    if (self.onStateChange) {
        self.onStateChange(self.state);
    }
}

- (void)pause {
    if (self.state != PomodoroStateIdle && self.state != PomodoroStatePaused) {
        self.stateBeforePause = self.state;
        self.state = PomodoroStatePaused;
        [self.timer invalidate];

        if (self.onStateChange) {
            self.onStateChange(self.state);
        }
    }
}

- (void)resume {
    if (self.state == PomodoroStatePaused) {
        self.state = self.stateBeforePause;
        [self startTimer];

        if (self.onStateChange) {
            self.onStateChange(self.state);
        }
    }
}

- (void)stop {
    [self.timer invalidate];
    self.state = PomodoroStateIdle;
    self.remainingSeconds = 0;

    if (self.onStateChange) {
        self.onStateChange(self.state);
    }
}

- (void)skip {
    [self.timer invalidate];
    [self transitionToNextState];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)tick {
    self.remainingSeconds--;

    if (self.onTick) {
        self.onTick(self.remainingSeconds, self.state);
    }

    if (self.remainingSeconds <= 0) {
        [self.timer invalidate];
        [self transitionToNextState];
    }
}

- (void)transitionToNextState {
    if (self.state == PomodoroStateWork) {
        self.completedPomodoros++;
        [self saveStats];

        if (self.onPomodoroComplete) {
            self.onPomodoroComplete(self.completedPomodoros);
        }

        [self showNotification:@"Focus Session Complete" body:@"Great work! Time for a break."];

        if (self.completedPomodoros % 4 == 0) {
            self.state = PomodoroStateLongBreak;
            self.remainingSeconds = self.longBreakDuration;
        } else {
            self.state = PomodoroStateShortBreak;
            self.remainingSeconds = self.shortBreakDuration;
        }
    } else {
        [self showNotification:@"Break Complete" body:@"Ready to focus again?"];
        self.state = PomodoroStateWork;
        self.remainingSeconds = self.workDuration;
    }

    [self startTimer];

    if (self.onStateChange) {
        self.onStateChange(self.state);
    }
}

- (void)showNotification:(NSString *)title body:(NSString *)body {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.sound = [UNNotificationSound defaultSound];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                          content:content
                                                                          trigger:nil];

    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                           withCompletionHandler:nil];
}

- (NSString *)formattedTime {
    NSInteger minutes = self.remainingSeconds / 60;
    NSInteger seconds = self.remainingSeconds % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (NSString *)stateDescription {
    switch (self.state) {
        case PomodoroStateIdle: return @"Ready";
        case PomodoroStateWork: return @"Focus";
        case PomodoroStateShortBreak: return @"Short Break";
        case PomodoroStateLongBreak: return @"Long Break";
        case PomodoroStatePaused: return @"Paused";
    }
}

@end
