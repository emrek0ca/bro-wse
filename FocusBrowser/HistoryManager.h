#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HistoryItem : NSObject <NSSecureCoding>
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSDate *timestamp;
@end

@interface HistoryManager : NSObject

+ (instancetype)sharedManager;
- (void)addHistoryItemWithTitle:(NSString *)title urlString:(NSString *)urlString;
- (NSArray<HistoryItem *> *)allHistory;
- (void)clearHistory;

@end

NS_ASSUME_NONNULL_END
