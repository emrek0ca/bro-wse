#import "DailyGoals.h"
#import "FocusStats.h"

static NSString *const kTargetFocusKey = @"FocusBrowser_TargetFocusMinutes";
static NSString *const kTargetPomodorosKey = @"FocusBrowser_TargetPomodoros";

@interface DailyGoals ()

@property(assign, nonatomic, readwrite) NSInteger currentFocusMinutes;
@property(assign, nonatomic, readwrite) NSInteger currentPomodoros;

@end

@implementation DailyGoals

+ (instancetype)sharedGoals {
  static DailyGoals *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[DailyGoals alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self loadSettings];
    [self refresh];
  }
  return self;
}

- (void)loadSettings {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  _targetFocusMinutes = [defaults objectForKey:kTargetFocusKey]
                            ? [defaults integerForKey:kTargetFocusKey]
                            : 120;
  _targetPomodoros = [defaults objectForKey:kTargetPomodorosKey]
                         ? [defaults integerForKey:kTargetPomodorosKey]
                         : 4;
}

- (void)setTargetFocusMinutes:(NSInteger)targetFocusMinutes {
  _targetFocusMinutes = targetFocusMinutes;
  [[NSUserDefaults standardUserDefaults] setInteger:targetFocusMinutes
                                             forKey:kTargetFocusKey];
}

- (void)setTargetPomodoros:(NSInteger)targetPomodoros {
  _targetPomodoros = targetPomodoros;
  [[NSUserDefaults standardUserDefaults] setInteger:targetPomodoros
                                             forKey:kTargetPomodorosKey];
}

- (void)refresh {
  DailyStats *today = [[FocusStats sharedStats] todayStats];
  self.currentFocusMinutes = today.focusMinutes;
  self.currentPomodoros = today.pomodorosCompleted;
}

- (CGFloat)focusProgress {
  if (self.targetFocusMinutes == 0)
    return 1.0;
  return MIN(1.0, (CGFloat)self.currentFocusMinutes / self.targetFocusMinutes);
}

- (CGFloat)pomodoroProgress {
  if (self.targetPomodoros == 0)
    return 1.0;
  return MIN(1.0, (CGFloat)self.currentPomodoros / self.targetPomodoros);
}

- (BOOL)focusGoalMet {
  return self.currentFocusMinutes >= self.targetFocusMinutes;
}

- (BOOL)pomodoroGoalMet {
  return self.currentPomodoros >= self.targetPomodoros;
}

- (NSString *)progressDescription {
  NSInteger focusPercent = (NSInteger)(self.focusProgress * 100);
  return [NSString stringWithFormat:@"%ld min / %ld min (%ld%%)",
                                    (long)self.currentFocusMinutes,
                                    (long)self.targetFocusMinutes,
                                    (long)focusPercent];
}

@end
