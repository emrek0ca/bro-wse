#import "BlockedPageView.h"
#import <QuartzCore/QuartzCore.h>

@interface BlockedPageView ()

@property (strong, nonatomic) NSView *iconContainer;
@property (strong, nonatomic) NSTextField *titleLabel;
@property (strong, nonatomic) NSTextField *messageLabel;
@property (strong, nonatomic) NSTextField *domainLabel;
@property (strong, nonatomic) NSButton *goBackButton;
@property (strong, nonatomic) NSTextField *quoteLabel;

@end

@implementation BlockedPageView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.backgroundColor = [[NSColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1] CGColor];

    // Shield icon container
    self.iconContainer = [[NSView alloc] init];
    self.iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconContainer.wantsLayer = YES;
    self.iconContainer.layer.cornerRadius = 50;
    self.iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:1] CGColor];
    [self addSubview:self.iconContainer];

    // Shield symbol
    NSTextField *shieldIcon = [[NSTextField alloc] init];
    shieldIcon.translatesAutoresizingMaskIntoConstraints = NO;
    shieldIcon.stringValue = @"⬡";
    shieldIcon.font = [NSFont systemFontOfSize:48 weight:NSFontWeightUltraLight];
    shieldIcon.bordered = NO;
    shieldIcon.editable = NO;
    shieldIcon.selectable = NO;
    shieldIcon.drawsBackground = NO;
    shieldIcon.textColor = [NSColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1];
    shieldIcon.alignment = NSTextAlignmentCenter;
    [self.iconContainer addSubview:shieldIcon];

    // Title
    self.titleLabel = [[NSTextField alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.stringValue = @"Stay Focused";
    self.titleLabel.bordered = NO;
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.drawsBackground = NO;
    self.titleLabel.font = [NSFont systemFontOfSize:28 weight:NSFontWeightSemibold];
    self.titleLabel.textColor = [NSColor whiteColor];
    self.titleLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];

    // Message
    self.messageLabel = [[NSTextField alloc] init];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageLabel.stringValue = @"This site is blocked during your focus session.";
    self.messageLabel.bordered = NO;
    self.messageLabel.editable = NO;
    self.messageLabel.selectable = NO;
    self.messageLabel.drawsBackground = NO;
    self.messageLabel.font = [NSFont systemFontOfSize:15 weight:NSFontWeightRegular];
    self.messageLabel.textColor = [NSColor colorWithWhite:1 alpha:0.7];
    self.messageLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.messageLabel];

    // Domain
    self.domainLabel = [[NSTextField alloc] init];
    self.domainLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.domainLabel.bordered = NO;
    self.domainLabel.editable = NO;
    self.domainLabel.selectable = NO;
    self.domainLabel.drawsBackground = NO;
    self.domainLabel.font = [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightMedium];
    self.domainLabel.textColor = [NSColor colorWithRed:1 green:0.5 blue:0.5 alpha:1];
    self.domainLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.domainLabel];

    // Go Back button
    self.goBackButton = [[NSButton alloc] init];
    self.goBackButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.goBackButton.title = @"Go Back";
    self.goBackButton.bezelStyle = NSBezelStyleRounded;
    self.goBackButton.target = self;
    self.goBackButton.action = @selector(goBackClicked:);
    self.goBackButton.wantsLayer = YES;
    [self addSubview:self.goBackButton];

    // Quote
    self.quoteLabel = [[NSTextField alloc] init];
    self.quoteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.quoteLabel.bordered = NO;
    self.quoteLabel.editable = NO;
    self.quoteLabel.selectable = NO;
    self.quoteLabel.drawsBackground = NO;
    self.quoteLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightLight];
    self.quoteLabel.textColor = [NSColor colorWithWhite:1 alpha:0.4];
    self.quoteLabel.alignment = NSTextAlignmentCenter;
    [self setRandomQuote];
    [self addSubview:self.quoteLabel];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.iconContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.iconContainer.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-80],
        [self.iconContainer.widthAnchor constraintEqualToConstant:100],
        [self.iconContainer.heightAnchor constraintEqualToConstant:100],

        [shieldIcon.centerXAnchor constraintEqualToAnchor:self.iconContainer.centerXAnchor],
        [shieldIcon.centerYAnchor constraintEqualToAnchor:self.iconContainer.centerYAnchor],

        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.iconContainer.bottomAnchor constant:24],
        [self.titleLabel.widthAnchor constraintEqualToConstant:400],

        [self.messageLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.messageLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.messageLabel.widthAnchor constraintEqualToConstant:400],

        [self.domainLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.domainLabel.topAnchor constraintEqualToAnchor:self.messageLabel.bottomAnchor constant:16],
        [self.domainLabel.widthAnchor constraintEqualToConstant:300],

        [self.goBackButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.goBackButton.topAnchor constraintEqualToAnchor:self.domainLabel.bottomAnchor constant:24],
        [self.goBackButton.widthAnchor constraintEqualToConstant:100],

        [self.quoteLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.quoteLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-40],
        [self.quoteLabel.widthAnchor constraintEqualToConstant:450],
    ]];
}

- (void)setBlockedDomain:(NSString *)blockedDomain {
    _blockedDomain = blockedDomain;
    self.domainLabel.stringValue = blockedDomain ?: @"";
}

- (void)setRandomQuote {
    NSArray *quotes = @[
        @"\"The successful warrior is the average man, with laser-like focus.\" — Bruce Lee",
        @"\"Concentrate all your thoughts upon the work at hand.\" — Alexander Graham Bell",
        @"\"Focus on being productive instead of busy.\" — Tim Ferriss",
        @"\"Your focus determines your reality.\" — George Lucas",
        @"\"Starve your distractions, feed your focus.\"",
        @"\"Where focus goes, energy flows.\" — Tony Robbins"
    ];

    NSInteger randomIndex = arc4random_uniform((uint32_t)quotes.count);
    self.quoteLabel.stringValue = quotes[randomIndex];
}

- (void)goBackClicked:(id)sender {
    if (self.onGoBack) {
        self.onGoBack();
    }
}

@end
