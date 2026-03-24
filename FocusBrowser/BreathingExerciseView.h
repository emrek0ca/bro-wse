#import <Cocoa/Cocoa.h>

@interface BreathingExerciseView : NSView

@property (copy, nonatomic) void (^onClose)(void);

- (void)startExercise;
- (void)stopExercise;

@end
