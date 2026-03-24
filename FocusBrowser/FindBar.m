#import "FindBar.h"

@interface FindBar () <NSTextFieldDelegate>

@property (strong, nonatomic) NSTextField *searchField;
@property (strong, nonatomic) NSTextField *resultLabel;
@property (strong, nonatomic) NSButton *prevButton;
@property (strong, nonatomic) NSButton *nextButton;
@property (strong, nonatomic) NSButton *closeButton;

@end

@implementation FindBar

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    self.layer.borderColor = [[NSColor separatorColor] CGColor];
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 8;

    // Search field
    self.searchField = [[NSTextField alloc] init];
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchField.placeholderString = @"Find in page...";
    self.searchField.font = [NSFont systemFontOfSize:13];
    self.searchField.bezelStyle = NSTextFieldRoundedBezel;
    self.searchField.delegate = self;
    self.searchField.target = self;
    self.searchField.action = @selector(findNext:);
    [self addSubview:self.searchField];

    // Result label
    self.resultLabel = [[NSTextField alloc] init];
    self.resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultLabel.bordered = NO;
    self.resultLabel.editable = NO;
    self.resultLabel.selectable = NO;
    self.resultLabel.drawsBackground = NO;
    self.resultLabel.font = [NSFont systemFontOfSize:11];
    self.resultLabel.textColor = [NSColor secondaryLabelColor];
    self.resultLabel.stringValue = @"";
    [self addSubview:self.resultLabel];

    // Previous button
    self.prevButton = [[NSButton alloc] init];
    self.prevButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.prevButton.title = @"◂";
    self.prevButton.bordered = NO;
    self.prevButton.font = [NSFont systemFontOfSize:12];
    self.prevButton.target = self;
    self.prevButton.action = @selector(findPrevious:);
    [self addSubview:self.prevButton];

    // Next button
    self.nextButton = [[NSButton alloc] init];
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.nextButton.title = @"▸";
    self.nextButton.bordered = NO;
    self.nextButton.font = [NSFont systemFontOfSize:12];
    self.nextButton.target = self;
    self.nextButton.action = @selector(findNext:);
    [self addSubview:self.nextButton];

    // Close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.title = @"×";
    self.closeButton.bordered = NO;
    self.closeButton.font = [NSFont systemFontOfSize:16 weight:NSFontWeightMedium];
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeClicked:);
    [self addSubview:self.closeButton];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.searchField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.searchField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.searchField.widthAnchor constraintEqualToConstant:200],

        [self.resultLabel.leadingAnchor constraintEqualToAnchor:self.searchField.trailingAnchor constant:8],
        [self.resultLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [self.prevButton.leadingAnchor constraintEqualToAnchor:self.resultLabel.trailingAnchor constant:8],
        [self.prevButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.prevButton.widthAnchor constraintEqualToConstant:24],

        [self.nextButton.leadingAnchor constraintEqualToAnchor:self.prevButton.trailingAnchor constant:4],
        [self.nextButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.nextButton.widthAnchor constraintEqualToConstant:24],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:24],
    ]];
}

- (void)show {
    self.hidden = NO;
    self.alphaValue = 0;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.15;
        self.animator.alphaValue = 1;
    }];
}

- (void)hide {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.15;
        self.animator.alphaValue = 0;
    } completionHandler:^{
        self.hidden = YES;
        [self clearHighlights];
    }];
}

- (void)focus {
    [self.window makeFirstResponder:self.searchField];
    [self.searchField selectText:nil];
}

- (void)findNext:(id)sender {
    NSString *query = self.searchField.stringValue;
    if (query.length == 0) return;

    WKFindConfiguration *config = [[WKFindConfiguration alloc] init];
    config.backwards = NO;
    config.caseSensitive = NO;
    config.wraps = YES;

    [self.webView findString:query withConfiguration:config completionHandler:^(WKFindResult *result) {
        if (result.matchFound) {
            self.resultLabel.stringValue = @"Found";
            self.resultLabel.textColor = [NSColor secondaryLabelColor];
        } else {
            self.resultLabel.stringValue = @"Not found";
            self.resultLabel.textColor = [NSColor systemRedColor];
        }
    }];
}

- (void)findPrevious:(id)sender {
    NSString *query = self.searchField.stringValue;
    if (query.length == 0) return;

    WKFindConfiguration *config = [[WKFindConfiguration alloc] init];
    config.backwards = YES;
    config.caseSensitive = NO;
    config.wraps = YES;

    [self.webView findString:query withConfiguration:config completionHandler:^(WKFindResult *result) {
        if (result.matchFound) {
            self.resultLabel.stringValue = @"Found";
            self.resultLabel.textColor = [NSColor secondaryLabelColor];
        } else {
            self.resultLabel.stringValue = @"Not found";
            self.resultLabel.textColor = [NSColor systemRedColor];
        }
    }];
}

- (void)clearHighlights {
    self.searchField.stringValue = @"";
    self.resultLabel.stringValue = @"";
}

- (void)closeClicked:(id)sender {
    [self hide];
    if (self.onClose) {
        self.onClose();
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    [self findNext:nil];
}

@end
