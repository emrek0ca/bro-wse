#import "QuickNotesPanel.h"

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
    self.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    self.layer.borderColor = [[NSColor separatorColor] CGColor];
    self.layer.borderWidth = 1;

    // Title
    self.titleLabel = [[NSTextField alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.stringValue = @"Quick Notes";
    self.titleLabel.bordered = NO;
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.drawsBackground = NO;
    self.titleLabel.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
    [self addSubview:self.titleLabel];

    // Close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.title = @"×";
    self.closeButton.bordered = NO;
    self.closeButton.font = [NSFont systemFontOfSize:18 weight:NSFontWeightMedium];
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeClicked:);
    [self addSubview:self.closeButton];

    // Clear button
    self.clearButton = [[NSButton alloc] init];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.clearButton.title = @"Clear";
    self.clearButton.bordered = NO;
    self.clearButton.font = [NSFont systemFontOfSize:11];
    self.clearButton.target = self;
    self.clearButton.action = @selector(clearNotes:);
    [self addSubview:self.clearButton];

    // Text view in scroll view
    self.scrollView = [[NSScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.borderType = NSBezelBorder;

    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 200, 300)];
    self.textView.delegate = self;
    self.textView.font = [NSFont systemFontOfSize:13];
    self.textView.textContainerInset = NSMakeSize(8, 8);
    self.textView.allowsUndo = YES;
    self.textView.richText = NO;
    self.textView.automaticQuoteSubstitutionEnabled = NO;
    self.textView.automaticDashSubstitutionEnabled = NO;

    self.scrollView.documentView = self.textView;
    [self addSubview:self.scrollView];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [self.closeButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [self.closeButton.widthAnchor constraintEqualToConstant:24],

        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.closeButton.leadingAnchor constant:-4],
        [self.clearButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],

        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-12],
    ]];
}

- (void)loadNotes {
    NSString *notes = [[NSUserDefaults standardUserDefaults] stringForKey:kNotesKey];
    if (notes) {
        self.textView.string = notes;
    }
}

- (void)saveNotes {
    [[NSUserDefaults standardUserDefaults] setObject:self.textView.string forKey:kNotesKey];
}

- (void)show {
    self.panelVisible = YES;
    self.hidden = NO;
    self.alphaValue = 0;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        self.animator.alphaValue = 1;
    }];
    [self.window makeFirstResponder:self.textView];
}

- (void)hide {
    self.panelVisible = NO;
    [self saveNotes];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
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
    self.textView.string = @"";
    [self saveNotes];
}

- (void)textDidChange:(NSNotification *)notification {
    [self saveNotes];
}

@end
