#import "FocusModeManager.h"

@interface FocusModeManager ()

@property (assign, nonatomic, readwrite) BOOL isEnabled;

@end

@implementation FocusModeManager

+ (instancetype)sharedManager {
    static FocusModeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FocusModeManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isEnabled = NO;
    }
    return self;
}

- (void)toggle {
    [self setEnabled:!self.isEnabled];
}

- (void)setEnabled:(BOOL)enabled {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    if (self.toggleHandler) {
        self.toggleHandler(enabled);
    }
}

@end
