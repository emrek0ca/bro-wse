#import "BreathingExerciseView.h"
#import "ThemeManager.h"
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, BreathingPhase) {
    BreathingPhaseInhale,
    BreathingPhaseHold,
    BreathingPhaseExhale,
    BreathingPhaseRest
};

@interface BreathingExerciseView ()

@property (strong, nonatomic) NSView *circleView;
@property (strong, nonatomic) NSView *innerCircle;
@property (strong, nonatomic) NSTextField *instructionLabel;
@property (strong, nonatomic) NSTextField *timerLabel;
@property (strong, nonatomic) NSTextField *cycleLabel;
@property (strong, nonatomic) NSButton *closeButton;
@property (strong, nonatomic) NSButton *startStopButton;

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) BreathingPhase currentPhase;
@property (assign, nonatomic) NSInteger phaseSeconds;
@property (assign, nonatomic) NSInteger cycleCount;
@property (assign, nonatomic) BOOL isRunning;

@property (assign, nonatomic) NSInteger inhaleTime;
@property (assign, nonatomic) NSInteger holdTime;
@property (assign, nonatomic) NSInteger exhaleTime;

@end

@implementation BreathingExerciseView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _inhaleTime = 4;
        _holdTime = 7;
        _exhaleTime = 8;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    
    // Modern Glassmorphism background
    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] init];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    blurView.material = NSVisualEffectMaterialFullScreenUI;
    blurView.state = NSVisualEffectStateActive;
    [self addSubview:blurView];
    
    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    // Outer circle
    self.circleView = [[NSView alloc] init];
    self.circleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.circleView.wantsLayer = YES;
    self.circleView.layer.cornerRadius = 100;
    self.circleView.layer.borderColor = [[ThemeManager sharedManager] accentColor].CGColor;
    self.circleView.layer.borderWidth = 1.5;
    self.circleView.layer.opacity = 0.3;
    [self addSubview:self.circleView];

    // Inner circle (animated)
    self.innerCircle = [[NSView alloc] init];
    self.innerCircle.translatesAutoresizingMaskIntoConstraints = NO;
    self.innerCircle.wantsLayer = YES;
    self.innerCircle.layer.cornerRadius = 70;
    self.innerCircle.layer.backgroundColor = [[ThemeManager sharedManager] accentColor].CGColor;
    self.innerCircle.layer.opacity = 0.4;
    [self.circleView addSubview:self.innerCircle];

    // Instruction label
    self.instructionLabel = [[NSTextField alloc] init];
    self.instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.instructionLabel.stringValue = @"Ready";
    self.instructionLabel.bordered = NO;
    self.instructionLabel.editable = NO;
    self.instructionLabel.selectable = NO;
    self.instructionLabel.drawsBackground = NO;
    self.instructionLabel.font = [NSFont systemFontOfSize:28 weight:NSFontWeightMedium];
    self.instructionLabel.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    self.instructionLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.instructionLabel];

    // Timer label
    self.timerLabel = [[NSTextField alloc] init];
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timerLabel.stringValue = @"";
    self.timerLabel.bordered = NO;
    self.timerLabel.editable = NO;
    self.timerLabel.selectable = NO;
    self.timerLabel.drawsBackground = NO;
    self.timerLabel.font = [NSFont monospacedDigitSystemFontOfSize:52 weight:NSFontWeightLight];
    self.timerLabel.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    self.timerLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.timerLabel];

    // Cycle label
    self.cycleLabel = [[NSTextField alloc] init];
    self.cycleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.cycleLabel.stringValue = @"4-7-8 Breathing Technique";
    self.cycleLabel.bordered = NO;
    self.cycleLabel.editable = NO;
    self.cycleLabel.selectable = NO;
    self.cycleLabel.drawsBackground = NO;
    self.cycleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    self.cycleLabel.textColor = [[ThemeManager sharedManager] textSecondaryColor];
    self.cycleLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.cycleLabel];

    // Close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.title = @"";
    self.closeButton.bordered = NO;
    if (@available(macOS 11.0, *)) {
        self.closeButton.image = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:@"Done"];
        self.closeButton.contentTintColor = [[ThemeManager sharedManager] textTertiaryColor];
    }
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeClicked:);
    [self addSubview:self.closeButton];

    // Start/Stop button
    self.startStopButton = [[NSButton alloc] init];
    self.startStopButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.startStopButton.title = @"Begin";
    self.startStopButton.bezelStyle = NSBezelStyleRounded;
    self.startStopButton.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    self.startStopButton.target = self;
    self.startStopButton.action = @selector(startStopClicked:);
    [self addSubview:self.startStopButton];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.circleView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.circleView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-40],
        [self.circleView.widthAnchor constraintEqualToConstant:200],
        [self.circleView.heightAnchor constraintEqualToConstant:200],

        [self.innerCircle.centerXAnchor constraintEqualToAnchor:self.circleView.centerXAnchor],
        [self.innerCircle.centerYAnchor constraintEqualToAnchor:self.circleView.centerYAnchor],
        [self.innerCircle.widthAnchor constraintEqualToConstant:140],
        [self.innerCircle.heightAnchor constraintEqualToConstant:140],

        [self.timerLabel.centerXAnchor constraintEqualToAnchor:self.circleView.centerXAnchor],
        [self.timerLabel.centerYAnchor constraintEqualToAnchor:self.circleView.centerYAnchor],

        [self.instructionLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.instructionLabel.topAnchor constraintEqualToAnchor:self.circleView.bottomAnchor constant:32],
        [self.instructionLabel.widthAnchor constraintEqualToConstant:300],

        [self.cycleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.cycleLabel.topAnchor constraintEqualToAnchor:self.instructionLabel.bottomAnchor constant:12],
        [self.cycleLabel.widthAnchor constraintEqualToConstant:250],

        [self.closeButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:30],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-30],
        [self.closeButton.widthAnchor constraintEqualToConstant:32],
        [self.closeButton.heightAnchor constraintEqualToConstant:32],

        [self.startStopButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.startStopButton.topAnchor constraintEqualToAnchor:self.cycleLabel.bottomAnchor constant:32],
        [self.startStopButton.widthAnchor constraintEqualToConstant:120],
        [self.startStopButton.heightAnchor constraintEqualToConstant:36],
    ]];
}

- (void)startExercise {
    self.isRunning = YES;
    self.cycleCount = 0;
    self.currentPhase = BreathingPhaseInhale;
    self.phaseSeconds = self.inhaleTime;
    self.startStopButton.title = @"Stop";

    [self updateUI];
    [self animateCircleForPhase:self.currentPhase];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopExercise {
    self.isRunning = NO;
    [self.timer invalidate];
    self.timer = nil;
    self.startStopButton.title = @"Begin";
    self.instructionLabel.stringValue = @"Ready";
    self.timerLabel.stringValue = @"";
    self.cycleLabel.stringValue = @"4-7-8 Breathing Technique";

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.innerCircle.animator.layer.transform = CATransform3DIdentity;
    }];
}

- (void)tick {
    self.phaseSeconds--;

    if (self.phaseSeconds <= 0) {
        [self nextPhase];
    }

    [self updateUI];
}

- (void)nextPhase {
    switch (self.currentPhase) {
        case BreathingPhaseInhale:
            self.currentPhase = BreathingPhaseHold;
            self.phaseSeconds = self.holdTime;
            break;
        case BreathingPhaseHold:
            self.currentPhase = BreathingPhaseExhale;
            self.phaseSeconds = self.exhaleTime;
            break;
        case BreathingPhaseExhale:
            self.cycleCount++;
            if (self.cycleCount >= 4) {
                [self stopExercise];
                self.instructionLabel.stringValue = @"Complete";
                self.cycleLabel.stringValue = @"Well done. Feel relaxed.";
                return;
            }
            self.currentPhase = BreathingPhaseInhale;
            self.phaseSeconds = self.inhaleTime;
            break;
        default:
            break;
    }

    [self animateCircleForPhase:self.currentPhase];
}

- (void)updateUI {
    ThemeManager *theme = [ThemeManager sharedManager];
    NSString *instruction;
    NSColor *accent = theme.accentColor;
    
    switch (self.currentPhase) {
        case BreathingPhaseInhale:
            instruction = @"Breathe In";
            accent = [NSColor systemBlueColor];
            break;
        case BreathingPhaseHold:
            instruction = @"Hold";
            accent = [NSColor systemOrangeColor];
            break;
        case BreathingPhaseExhale:
            instruction = @"Breathe Out";
            accent = [NSColor systemGreenColor];
            break;
        default:
            instruction = @"Ready";
            break;
    }

    self.instructionLabel.stringValue = instruction;
    self.timerLabel.stringValue = (self.phaseSeconds > 0) ? [NSString stringWithFormat:@"%ld", (long)self.phaseSeconds] : @"";
    self.cycleLabel.stringValue = self.isRunning ? [NSString stringWithFormat:@"Cycle %ld of 4", (long)self.cycleCount + 1] : @"4-7-8 Breathing Technique";
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.5;
        self.innerCircle.animator.layer.backgroundColor = accent.CGColor;
        self.circleView.animator.layer.borderColor = accent.CGColor;
    }];
}

- (void)animateCircleForPhase:(BreathingPhase)phase {
    CGFloat scale;
    NSTimeInterval duration;

    switch (phase) {
        case BreathingPhaseInhale:
            scale = 1.4;
            duration = self.inhaleTime;
            break;
        case BreathingPhaseHold:
            scale = 1.4;
            duration = 0.1;
            break;
        case BreathingPhaseExhale:
            scale = 1.0;
            duration = self.exhaleTime;
            break;
        default:
            scale = 1.0;
            duration = 0.5;
            break;
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = duration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        self.innerCircle.animator.layer.transform = CATransform3DMakeScale(scale, scale, 1);
    }];
}

- (void)startStopClicked:(id)sender {
    if (self.isRunning) {
        [self stopExercise];
    } else {
        [self startExercise];
    }
}

- (void)closeClicked:(id)sender {
    [self stopExercise];
    if (self.onClose) {
        self.onClose();
    }
}

@end
