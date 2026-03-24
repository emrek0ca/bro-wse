#import "FocusEngine.h"
#import "AmbientSoundManager.h"
#import "FocusStats.h"
#import "SiteBlocker.h"
#import <UserNotifications/UserNotifications.h>

NSNotificationName const FocusStateDidChangeNotification =
    @"FocusStateDidChangeNotification";
NSNotificationName const FocusTimerDidTickNotification =
    @"FocusTimerDidTickNotification";

static NSString *const kPersistenceKey = @"FocusEngineSelectedState";

@interface FocusEngine ()

// State
@property(nonatomic, readwrite) FocusState state;
@property(nonatomic, readwrite) NSTimeInterval timeRemaining;
@property(nonatomic, readwrite) NSTimeInterval totalDuration;
@property(nonatomic, strong)
    NSDate *targetTimestamp; // Absolute completion time
@property(nonatomic, strong) NSString *currentSessionID;

// Internals
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, assign) BOOL isStrict;

@end

@implementation FocusEngine

#pragma mark - Initialization

+ (instancetype)sharedEngine {
  static FocusEngine *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FocusEngine alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _state = FocusStateIdle;
    _isStrict = YES;
    [self recoverState]; // Crash Recovery Algorithm
  }
  return self;
}

#pragma mark - Public API (Intents)

- (void)startFlowSession:(NSInteger)minutes strict:(BOOL)strict {
  if (self.state != FocusStateIdle) {
    NSLog(@"[FocusEngine] REJECTED StartFlow: State is not Idle");
    return;
  }

  NSLog(@"[FocusEngine] ACCEPTED StartFlow: %ld min", (long)minutes);
  self.isStrict = strict;

  // Create new session ID
  self.currentSessionID = [[NSUUID UUID] UUIDString];

  // Transition
  [self transitionToState:FocusStateFlow duration:minutes * 60];
}

- (void)abandonSession {
  if (self.state != FocusStateFlow) {
    return; // Silent ignore
  }

  NSLog(@"[FocusEngine] ABANDON Flow");
  // Metrics: Mark as blocked/failed? Or just incomplete.
  // For v2.0 we just go to Idle.
  [self transitionToState:FocusStateIdle duration:0];
}

- (void)skipBreak {
  if (self.state != FocusStateBreak) {
    return;
  }

  NSLog(@"[FocusEngine] SKIP Break");
  [self transitionToState:FocusStateIdle duration:0];
}

- (void)endSession {
  // General purpose end (Reset)
  [self transitionToState:FocusStateIdle duration:0];
}

#pragma mark - State Transition Logic

- (void)transitionToState:(FocusState)newState
                 duration:(NSTimeInterval)duration {
  FocusState oldState = self.state;

  // 1. Update State
  self.state = newState;
  self.totalDuration = duration;
  self.timeRemaining = duration;

  // 2. Setup Timer (Absolute)
  [self.timer invalidate];
  self.timer = nil;

  if (duration > 0) {
    self.targetTimestamp = [NSDate dateWithTimeIntervalSinceNow:duration];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
  } else {
    self.targetTimestamp = nil;
  }

  // 3. Persist State (For crash recovery)
  [self persistState];

  // 4. Execute Side Effects
  [self executeSideEffects];

  // 5. Notify
  NSDictionary *payload = @{
    @"currentState" : @(self.state),
    @"previousState" : @(oldState),
    @"sessionID" : self.currentSessionID ?: @"",
    @"timestamp" : [NSDate date]
  };

  [[NSNotificationCenter defaultCenter]
      postNotificationName:FocusStateDidChangeNotification
                    object:self
                  userInfo:payload];
}

- (void)tick {
  if (!self.targetTimestamp)
    return;

  NSTimeInterval remaining = [self.targetTimestamp timeIntervalSinceNow];
  self.timeRemaining = remaining;

  // Notify tick
  [[NSNotificationCenter defaultCenter]
      postNotificationName:FocusTimerDidTickNotification
                    object:self
                  userInfo:@{
                    @"timeRemaining" : @(MAX(0, remaining)),
                    @"progress" : @(self.progress)
                  }];

  if (remaining <= 0) {
    [self.timer invalidate];
    self.timer = nil;
    [self handleTimerComplete];
  }
}

- (void)handleTimerComplete {
  if (self.state == FocusStateFlow) {
    // Flow Complete -> Record & Break
    [[FocusStats sharedStats] incrementPomodoros];
    [[FocusStats sharedStats]
        addFocusMinutes:(NSInteger)(self.totalDuration / 60)];

    [self showNotification:@"Focus Session Complete"
                      body:@"Time to take a break."];
    [self transitionToState:FocusStateBreak duration:300]; // 5 min break

  } else if (self.state == FocusStateBreak) {
    // Break Complete -> Idle
    [self showNotification:@"Break Over" body:@"Ready for the next session?"];
    [self transitionToState:FocusStateIdle duration:0];
  }
}

#pragma mark - Side Effects (Strict Enforcement)

- (void)executeSideEffects {
  BOOL inFlow = (self.state == FocusStateFlow);

  // 1. Blocker
  [[SiteBlocker sharedBlocker] setIsEnabled:inFlow];

  // 2. Audio
  if (!inFlow) {
    // Stop audio if we leave Flow
    if ([[AmbientSoundManager sharedManager] isPlaying]) {
      [[AmbientSoundManager sharedManager] stop];
    }
  }
}

#pragma mark - Crash Recovery (Persistence)

- (void)persistState {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  dict[@"state"] = @(self.state);
  if (self.targetTimestamp) {
    dict[@"targetTimestamp"] = self.targetTimestamp;
  }
  if (self.currentSessionID) {
    dict[@"sessionID"] = self.currentSessionID;
  }
  dict[@"totalDuration"] = @(self.totalDuration);

  [defaults setObject:dict forKey:kPersistenceKey];
}

- (void)recoverState {
  NSDictionary *dict =
      [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPersistenceKey];
  if (!dict)
    return;

  FocusState savedState = [dict[@"state"] integerValue];
  if (savedState == FocusStateIdle)
    return;

  NSDate *target = dict[@"targetTimestamp"];
  self.currentSessionID = dict[@"sessionID"];
  self.totalDuration = [dict[@"totalDuration"] doubleValue];

  if (!target) {
    // Invalid state, reset
    [self transitionToState:FocusStateIdle duration:0];
    return;
  }

  NSTimeInterval remaining = [target timeIntervalSinceNow];

  if (remaining > 0) {
    // RESUME
    NSLog(@"[FocusEngine] Recovering active session...");
    self.state = savedState;
    self.targetTimestamp = target;
    self.timeRemaining = remaining;

    // Restart timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

    // Re-enforce side effects
    [self executeSideEffects];

  } else {
    // EXPIRED while sleeping/crashed
    NSLog(@"[FocusEngine] Session expired while inactive.");

    if (savedState == FocusStateFlow) {
      // Optimistic completion
      [[FocusStats sharedStats] incrementPomodoros];
      [[FocusStats sharedStats]
          addFocusMinutes:(NSInteger)(self.totalDuration / 60)];
      // Go to Break? Or Idle? Let's go to Idle so we don't start a break in the
      // past
      [self transitionToState:FocusStateIdle duration:0];
    } else {
      [self transitionToState:FocusStateIdle duration:0];
    }
  }
}

#pragma mark - Getters

- (BOOL)isZenModeActive {
  return self.state == FocusStateFlow;
}

- (CGFloat)progress {
  if (self.totalDuration <= 0)
    return 0;
  return 1.0 - (self.timeRemaining / self.totalDuration);
}

#pragma mark - Notifications

- (void)showNotification:(NSString *)title body:(NSString *)body {
  UNMutableNotificationContent *content =
      [[UNMutableNotificationContent alloc] init];
  content.title = title;
  content.body = body;
  content.sound = [UNNotificationSound defaultSound];

  UNNotificationRequest *request =
      [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                           content:content
                                           trigger:nil];

  [[UNUserNotificationCenter currentNotificationCenter]
      addNotificationRequest:request
       withCompletionHandler:nil];
}

@end
