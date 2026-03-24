#import <Foundation/Foundation.h>

@interface FocusSession : NSObject <NSCoding, NSSecureCoding>

@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) NSInteger durationMinutes;
@property (assign, nonatomic) BOOL blockSites;
@property (assign, nonatomic) BOOL strictMode;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSDate *endTime;

+ (instancetype)sessionWithName:(NSString *)name duration:(NSInteger)minutes;

@end

@interface FocusSessionManager : NSObject

@property (strong, nonatomic, readonly) FocusSession *activeSession;
@property (assign, nonatomic, readonly) BOOL isSessionActive;
@property (assign, nonatomic, readonly) NSInteger remainingSeconds;

@property (copy, nonatomic) void (^onSessionStart)(FocusSession *session);
@property (copy, nonatomic) void (^onSessionEnd)(FocusSession *session);
@property (copy, nonatomic) void (^onTick)(NSInteger remainingSeconds);

+ (instancetype)sharedManager;

- (void)startSession:(FocusSession *)session;
- (void)endSession;
- (NSArray<FocusSession *> *)sessionHistory;
- (NSArray<FocusSession *> *)presetSessions;
- (NSInteger)todayFocusMinutes;

@end
