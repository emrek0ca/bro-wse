#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, PomodoroState) {
    PomodoroStateIdle,
    PomodoroStateWork,
    PomodoroStateShortBreak,
    PomodoroStateLongBreak,
    PomodoroStatePaused
};

@interface PomodoroTimer : NSObject

@property (assign, nonatomic, readonly) PomodoroState state;
@property (assign, nonatomic, readonly) NSInteger remainingSeconds;
@property (assign, nonatomic, readonly) NSInteger completedPomodoros;
@property (assign, nonatomic) NSInteger workDuration;      // default 25 min
@property (assign, nonatomic) NSInteger shortBreakDuration; // default 5 min
@property (assign, nonatomic) NSInteger longBreakDuration;  // default 15 min

@property (copy, nonatomic) void (^onTick)(NSInteger remainingSeconds, PomodoroState state);
@property (copy, nonatomic) void (^onStateChange)(PomodoroState newState);
@property (copy, nonatomic) void (^onPomodoroComplete)(NSInteger totalCompleted);

+ (instancetype)sharedTimer;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)skip;
- (NSString *)formattedTime;
- (NSString *)stateDescription;

@end
