#import "AdBlockManager.h"

@implementation AdBlockManager

+ (instancetype)sharedManager {
  static AdBlockManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] init];
  });
  return shared;
}

- (void)compileRulesWithCompletion:
    (void (^)(WKContentRuleList *ruleList))completion {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"blocker_rules"
                                                   ofType:@"json"];
  if (!path) {
    NSLog(@"AdBlock: Rules file not found.");
    if (completion)
      completion(nil);
    return;
  }

  NSString *imgStr = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
  if (!imgStr) {
    if (completion)
      completion(nil);
    return;
  }

  [[WKContentRuleListStore defaultStore]
      compileContentRuleListForIdentifier:@"BlockList"
                   encodedContentRuleList:imgStr
                        completionHandler:^(
                            WKContentRuleList *_Nullable contentRuleList,
                            NSError *_Nullable error) {
                          if (error) {
                            NSLog(@"AdBlock Compilation Error: %@", error);
                            if (completion)
                              completion(nil);
                          } else {
                            NSLog(@"AdBlock: Rules compiled successfully.");
                            if (completion)
                              completion(contentRuleList);
                          }
                        }];
}

@end
