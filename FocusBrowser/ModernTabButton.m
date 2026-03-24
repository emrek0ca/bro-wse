#import "ModernTabButton.h"
#import "ThemeManager.h"
#import <QuartzCore/QuartzCore.h>

@interface ModernTabButton ()

@property (strong, nonatomic) NSTextField *titleLabel;
@property (strong, nonatomic) NSTextField *hostLabel;
@property (strong, nonatomic) NSButton *closeButton;
@property (strong, nonatomic) NSProgressIndicator *spinner;
@property (strong, nonatomic) NSImageView *faviconView;
@property (strong, nonatomic) NSTrackingArea *trackingArea;
@property (assign, nonatomic) BOOL isHovered;

@end

@implementation ModernTabButton

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(themeChanged)
                                                     name:ThemeDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 8;

    // Favicon
    self.faviconView = [[NSImageView alloc] init];
    self.faviconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.faviconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:self.faviconView];

    // Title
    self.titleLabel = [[NSTextField alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.bordered = NO;
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.drawsBackground = NO;
    self.titleLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.cell.truncatesLastVisibleLine = YES;
    [self addSubview:self.titleLabel];

    // Host
    self.hostLabel = [[NSTextField alloc] init];
    self.hostLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hostLabel.bordered = NO;
    self.hostLabel.editable = NO;
    self.hostLabel.selectable = NO;
    self.hostLabel.drawsBackground = NO;
    self.hostLabel.font = [NSFont systemFontOfSize:10];
    self.hostLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:self.hostLabel];

    // Loading spinner
    self.spinner = [[NSProgressIndicator alloc] init];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.style = NSProgressIndicatorStyleSpinning;
    self.spinner.controlSize = NSControlSizeMini;
    self.spinner.hidden = YES;
    [self addSubview:self.spinner];

    // Close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.bordered = NO;
    self.closeButton.title = @"";
    self.closeButton.bezelStyle = NSBezelStyleInline;
    self.closeButton.image = [NSImage imageWithSystemSymbolName:@"xmark" accessibilityDescription:@"Close"];
    self.closeButton.imagePosition = NSImageOnly;
    self.closeButton.imageScaling = NSImageScaleProportionallyDown;
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeClicked);
    self.closeButton.alphaValue = 0;
    [self addSubview:self.closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.faviconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [self.faviconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.faviconView.widthAnchor constraintEqualToConstant:16],
        [self.faviconView.heightAnchor constraintEqualToConstant:16],

        [self.spinner.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.spinner.widthAnchor constraintEqualToConstant:14],
        [self.spinner.heightAnchor constraintEqualToConstant:14],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.faviconView.trailingAnchor constant:8],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.closeButton.leadingAnchor constant:-4],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],

        [self.hostLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.hostLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.hostLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-6],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:18],
        [self.closeButton.heightAnchor constraintEqualToConstant:18],
    ]];

    [self updateAppearance];
}

- (void)themeChanged {
    [self updateAppearance];
}

- (void)updateAppearance {
    ThemeManager *theme = [ThemeManager sharedManager];

    if (self.isSelected) {
        self.layer.backgroundColor = [theme.surfaceColor CGColor];
        self.layer.borderWidth = 1;
        self.layer.borderColor = [theme.borderColor CGColor];
        self.titleLabel.textColor = theme.textPrimaryColor;
        self.hostLabel.textColor = theme.textSecondaryColor;
    } else if (self.isHovered) {
        self.layer.backgroundColor = [[theme.surfaceColor colorWithAlphaComponent:0.5] CGColor];
        self.layer.borderWidth = 0;
        self.titleLabel.textColor = theme.textPrimaryColor;
        self.hostLabel.textColor = theme.textSecondaryColor;
    } else {
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.layer.borderWidth = 0;
        self.titleLabel.textColor = theme.textSecondaryColor;
        self.hostLabel.textColor = theme.textTertiaryColor;
    }
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.stringValue = title ?: @"New Tab";
}

- (void)setUrlHost:(NSString *)urlHost {
    _urlHost = urlHost;
    self.hostLabel.stringValue = urlHost ?: @"";
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    [self updateAppearance];
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
    self.spinner.hidden = !isLoading;
    self.faviconView.hidden = isLoading;
    if (isLoading) [self.spinner startAnimation:nil];
    else [self.spinner stopAnimation:nil];
}

- (void)setFavicon:(NSImage *)favicon {
    _favicon = favicon;
    self.faviconView.image = favicon ?: [NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:nil];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.trackingArea) [self removeTrackingArea:self.trackingArea];

    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                       owner:self
                                                    userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    self.isHovered = YES;
    [self updateAppearance];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
        ctx.duration = 0.15;
        self.closeButton.animator.alphaValue = 1;
    }];
}

- (void)mouseExited:(NSEvent *)event {
    self.isHovered = NO;
    [self updateAppearance];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
        ctx.duration = 0.15;
        self.closeButton.animator.alphaValue = 0;
    }];
}

- (void)mouseDown:(NSEvent *)event {
    if (self.onSelect) self.onSelect();
}

- (void)closeClicked {
    if (self.onClose) self.onClose();
}

@end
