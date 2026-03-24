#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface AdBlockManager : NSObject

+ (instancetype)sharedManager;
- (void)compileRulesWithCompletion:
    (void (^)(WKContentRuleList *ruleList))completion;

@end
