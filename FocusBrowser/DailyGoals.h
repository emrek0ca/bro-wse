#import <Foundation/Foundation.h>

@interface DailyGoals : NSObject

@property (assign, nonatomic) NSInteger targetFocusMinutes;
@property (assign, nonatomic) NSInteger targetPomodoros;
@property (assign, nonatomic, readonly) NSInteger currentFocusMinutes;
@property (assign, nonatomic, readonly) NSInteger currentPomodoros;
@property (assign, nonatomic, readonly) CGFloat focusProgress;
@property (assign, nonatomic, readonly) CGFloat pomodoroProgress;
@property (assign, nonatomic, readonly) BOOL focusGoalMet;
@property (assign, nonatomic, readonly) BOOL pomodoroGoalMet;

+ (instancetype)sharedGoals;

- (void)refresh;
- (NSString *)progressDescription;

@end
