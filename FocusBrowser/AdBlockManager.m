#import "AdBlockManager.h"

@interface AdBlockManager ()
@property(strong, nonatomic) WKContentRuleList *cachedRuleList;
@property(assign, nonatomic) BOOL isCompiling;
@property(strong, nonatomic) NSMutableArray *pendingCompletions;
@end

@implementation AdBlockManager

+ (instancetype)sharedManager {
  static AdBlockManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] init];
  });
  return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pendingCompletions = [NSMutableArray array];
    }
    return self;
}

- (void)compileRulesWithCompletion:
    (void (^)(WKContentRuleList *ruleList))completion {
    
    @synchronized (self) {
        if (self.cachedRuleList) {
            if (completion) completion(self.cachedRuleList);
            return;
        }
        
        if (completion) {
            [self.pendingCompletions addObject:[completion copy]];
        }
        
        if (self.isCompiling) return;
        self.isCompiling = YES;
    }

  NSString *path = [[NSBundle mainBundle] pathForResource:@"blocker_rules"
                                                   ofType:@"json"];
  if (!path) {
    NSLog(@"AdBlock: Rules file not found.");
    [self notifyPendingWithList:nil];
    return;
  }

  NSError *error;
  NSString *rulesJson = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
  if (!rulesJson || error) {
    NSLog(@"AdBlock: Failed to read rules: %@", error);
    [self notifyPendingWithList:nil];
    return;
  }

  [[WKContentRuleListStore defaultStore]
      compileContentRuleListForIdentifier:@"FocusBlockList"
                   encodedContentRuleList:rulesJson
                        completionHandler:^(
                            WKContentRuleList *_Nullable contentRuleList,
                            NSError *_Nullable error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              @synchronized (self) {
                                  if (error) {
                                    NSLog(@"AdBlock Compilation Error: %@", error);
                                  } else {
                                    NSLog(@"AdBlock: Rules compiled successfully.");
                                    self.cachedRuleList = contentRuleList;
                                  }
                                  self.isCompiling = NO;
                                  [self notifyPendingWithList:contentRuleList];
                              }
                          });
                        }];
}

- (void)notifyPendingWithList:(WKContentRuleList *)list {
    NSArray *completions = [self.pendingCompletions copy];
    [self.pendingCompletions removeAllObjects];
    for (void (^completion)(WKContentRuleList *) in completions) {
        completion(list);
    }
}

@end
