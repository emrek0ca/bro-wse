#import "QuickNotesPanel.h"
#import "ThemeManager.h"

static NSString * const kNotesKey = @"FocusBrowser_QuickNotes";

@interface QuickNotesPanel () <NSTextViewDelegate>

@property (strong, nonatomic) NSTextField *titleLabel;
@property (strong, nonatomic) NSScrollView *scrollView;
@property (strong, nonatomic) NSTextView *textView;
@property (strong, nonatomic) NSButton *closeButton;
@property (strong, nonatomic) NSButton *clearButton;
@property (assign, nonatomic) BOOL panelVisible;

@end

@implementation QuickNotesPanel

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        [self loadNotes];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    
    // Modern Glassmorphism background
    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] init];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    blurView.material = NSVisualEffectMaterialSidebar;
    blurView.state = NSVisualEffectStateActive;
    [self addSubview:blurView];
    
    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    self.layer.borderColor = [[ThemeManager sharedManager] borderColor].CGColor;
    self.layer.borderWidth = 1;

    // Title
    self.titleLabel = [[NSTextField alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.stringValue = @"Quick Notes";
    self.titleLabel.bordered = NO;
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.drawsBackground = NO;
    self.titleLabel.font = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
    self.titleLabel.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    [self addSubview:self.titleLabel];

    // Close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.title = @"";
    self.closeButton.bordered = NO;
    if (@available(macOS 11.0, *)) {
        self.closeButton.image = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:@"Close"];
        self.closeButton.contentTintColor = [[ThemeManager sharedManager] textTertiaryColor];
    }
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeClicked:);
    [self addSubview:self.closeButton];

    // Clear button
    self.clearButton = [[NSButton alloc] init];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.clearButton.title = @"Clear All";
    self.clearButton.bordered = NO;
    self.clearButton.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
    self.clearButton.contentTintColor = [NSColor systemRedColor];
    self.clearButton.target = self;
    self.clearButton.action = @selector(clearNotes:);
    [self addSubview:self.clearButton];

    // Text view in scroll view
    self.scrollView = [[NSScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.drawsBackground = NO;
    self.scrollView.borderType = NSNoBorder;

    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 200, 300)];
    self.textView.delegate = self;
    self.textView.font = [NSFont systemFontOfSize:14];
    self.textView.textContainerInset = NSMakeSize(12, 12);
    self.textView.allowsUndo = YES;
    self.textView.richText = NO;
    self.textView.drawsBackground = NO;
    self.textView.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    self.textView.insertionPointColor = [[ThemeManager sharedManager] accentColor];
    self.textView.automaticQuoteSubstitutionEnabled = NO;
    self.textView.automaticDashSubstitutionEnabled = NO;

    self.scrollView.documentView = self.textView;
    [self addSubview:self.scrollView];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:24],
        [self.closeButton.heightAnchor constraintEqualToConstant:24],

        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.closeButton.leadingAnchor constant:-8],
        [self.clearButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],

        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (void)loadNotes {
    NSString *notes = [[NSUserDefaults standardUserDefaults] stringForKey:kNotesKey];
    if (notes) {
        self.textView.string = notes;
    }
}

- (void)saveNotes {
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.string ?: @"" forKey:kNotesKey];
}

- (void)show {
    self.panelVisible = YES;
    self.hidden = NO;
    self.alphaValue = 0;
    
    // Animation: Fade in and slide slightly
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        self.animator.alphaValue = 1.0;
    }];
    [self.window makeFirstResponder:self.textView];
}

- (void)hide {
    self.panelVisible = NO;
    [self saveNotes];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.25;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        self.animator.alphaValue = 0;
    } completionHandler:^{
        self.hidden = YES;
    }];

    if (self.onClose) {
        self.onClose();
    }
}

- (void)toggle {
    if (self.panelVisible) {
        [self hide];
    } else {
        [self show];
    }
}

- (BOOL)isVisible {
    return self.panelVisible;
}

- (void)closeClicked:(id)sender {
    [self hide];
}

- (void)clearNotes:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear all notes?";
    alert.informativeText = @"This action cannot be undone.";
    [alert addButtonWithTitle:@"Clear"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        self.textView.string = @"";
        [self saveNotes];
    }
}

- (void)textDidChange:(NSNotification *)notification {
    [self saveNotes];
}

- (void)updateLayer {
    [super updateLayer];
    self.layer.borderColor = [[ThemeManager sharedManager] borderColor].CGColor;
    self.textView.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    self.textView.insertionPointColor = [[ThemeManager sharedManager] accentColor];
}

@end
