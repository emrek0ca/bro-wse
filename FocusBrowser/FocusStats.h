#import <Foundation/Foundation.h>

@interface DailyStats : NSObject <NSCoding, NSSecureCoding>

@property (copy, nonatomic) NSString *date;
@property (assign, nonatomic) NSInteger focusMinutes;
@property (assign, nonatomic) NSInteger pomodorosCompleted;
@property (assign, nonatomic) NSInteger sitesBlocked;
@property (assign, nonatomic) NSInteger pagesVisited;
@property (assign, nonatomic) CGFloat focusScore;

@end

@interface FocusStats : NSObject

+ (instancetype)sharedStats;

- (DailyStats *)todayStats;
- (NSArray<DailyStats *> *)weeklyStats;

- (void)addFocusMinutes:(NSInteger)minutes;
- (void)incrementPomodoros;
- (void)incrementBlockedSites;
- (void)incrementPagesVisited;
- (void)recordSiteVisit:(NSString *)domain duration:(NSInteger)seconds;

- (CGFloat)calculateFocusScore;
- (NSString *)focusScoreDescription;

@end
