#import "TabButton.h"
#import "ThemeManager.h"

@interface TabButton ()

@property(strong, nonatomic) NSTextField *titleLabel;
@property(strong, nonatomic) NSButton *closeButton;
@property(strong, nonatomic) NSTrackingArea *trackingArea;
@property(assign, nonatomic) BOOL isHovered;

@end

@implementation TabButton

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.wantsLayer = YES;
  self.layer.cornerRadius = 6;

  // Title label
  self.titleLabel = [[NSTextField alloc] init];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.titleLabel.bordered = NO;
  self.titleLabel.editable = NO;
  self.titleLabel.selectable = NO;
  self.titleLabel.drawsBackground = NO;
  self.titleLabel.font = [NSFont systemFontOfSize:11];
  self.titleLabel.textColor = [NSColor labelColor];
  self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.titleLabel.alignment = NSTextAlignmentCenter;
  [self addSubview:self.titleLabel];

  // Close button
  self.closeButton = [[NSButton alloc] init];
  self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.closeButton.title = @"×";
  self.closeButton.bordered = NO;
  self.closeButton.font = [NSFont systemFontOfSize:14
                                            weight:NSFontWeightMedium];
  self.closeButton.target = self;
  self.closeButton.action = @selector(closeClicked:);
  self.closeButton.alphaValue = 0;
  [self.closeButton setButtonType:NSButtonTypeMomentaryPushIn];
  [self addSubview:self.closeButton];

  // Constraints
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                  constant:8],
    [self.titleLabel.trailingAnchor
        constraintEqualToAnchor:self.closeButton.leadingAnchor
                       constant:-4],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

    [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                    constant:-4],
    [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.closeButton.widthAnchor constraintEqualToConstant:18],
    [self.closeButton.heightAnchor constraintEqualToConstant:18],
  ]];

  [self updateTrackingArea];
}

- (void)updateTrackingArea {
  if (self.trackingArea) {
    [self removeTrackingArea:self.trackingArea];
  }
  self.trackingArea = [[NSTrackingArea alloc]
      initWithRect:self.bounds
           options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
             owner:self
          userInfo:nil];
  [self addTrackingArea:self.trackingArea];
}

- (void)layout {
  [super layout];
  [self updateTrackingArea];
}

- (void)setTitle:(NSString *)title {
  _title = title;
  NSString *displayTitle = title ?: @"New Tab";
  if (displayTitle.length > 25) {
    displayTitle =
        [[displayTitle substringToIndex:22] stringByAppendingString:@"…"];
  }
  self.titleLabel.stringValue = displayTitle;
}

- (void)setIsSelected:(BOOL)isSelected {
  _isSelected = isSelected;
  [self updateAppearance];
}

- (void)updateAppearance {
  ThemeManager *theme = [ThemeManager sharedManager];

  if (self.isSelected) {
    self.layer.backgroundColor = [theme surfaceColor].CGColor;

    // Add subtle shadow for active tab
    self.layer.shadowColor = [NSColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.1;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 2;

    self.titleLabel.textColor = [theme textPrimaryColor];
  } else if (self.isHovered) {
    NSColor *hoverColor =
        [theme.isDarkMode ? [NSColor whiteColor] : [NSColor blackColor]
            colorWithAlphaComponent:0.05];
    self.layer.backgroundColor = hoverColor.CGColor;
    self.layer.shadowOpacity = 0;
    self.titleLabel.textColor = [theme textSecondaryColor];
  } else {
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.layer.shadowOpacity = 0;
    self.titleLabel.textColor = [theme textSecondaryColor];
  }
}

- (void)mouseEntered:(NSEvent *)event {
  self.isHovered = YES;
  [self updateAppearance];

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.duration = 0.15;
    self.closeButton.animator.alphaValue = 1;
  }];
}

- (void)mouseExited:(NSEvent *)event {
  self.isHovered = NO;
  [self updateAppearance];

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.duration = 0.15;
    self.closeButton.animator.alphaValue = 0;
  }];
}

- (void)mouseDown:(NSEvent *)event {
  if (self.onSelect) {
    self.onSelect();
  }
}

- (void)closeClicked:(id)sender {
  if (self.onClose) {
    self.onClose();
  }
}

@end
