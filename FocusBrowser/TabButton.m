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
  self.layer.cornerRadius = 8;

  // Title label
  self.titleLabel = [[NSTextField alloc] init];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.titleLabel.bordered = NO;
  self.titleLabel.editable = NO;
  self.titleLabel.selectable = NO;
  self.titleLabel.drawsBackground = NO;
  self.titleLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
  self.titleLabel.textColor = [[ThemeManager sharedManager] textPrimaryColor];
  self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.titleLabel.alignment = NSTextAlignmentLeft;
  [self addSubview:self.titleLabel];

  // Close button
  self.closeButton = [[NSButton alloc] init];
  self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.closeButton.bordered = NO;
  self.closeButton.target = self;
  self.closeButton.action = @selector(closeClicked:);
  self.closeButton.alphaValue = 0;
  [self.closeButton setButtonType:NSButtonTypeMomentaryPushIn];
  
  if (@available(macOS 11.0, *)) {
      NSImage *closeImg = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:@"Close"];
      NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration configurationWithPointSize:10 weight:NSFontWeightBold];
      self.closeButton.image = [closeImg imageWithSymbolConfiguration:config];
      self.closeButton.imagePosition = NSImageOnly;
      self.closeButton.contentTintColor = [[ThemeManager sharedManager] textSecondaryColor];
  } else {
      self.closeButton.title = @"×";
  }
  
  [self addSubview:self.closeButton];

  // Constraints
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                  constant:12],
    [self.titleLabel.trailingAnchor
        constraintEqualToAnchor:self.closeButton.leadingAnchor
                       constant:-4],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

    [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                    constant:-8],
    [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.closeButton.widthAnchor constraintEqualToConstant:16],
    [self.closeButton.heightAnchor constraintEqualToConstant:16],
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
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [theme borderColor].CGColor;
    
    // Apple-style subtle shadow
    self.layer.shadowColor = [NSColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.05;
    self.layer.shadowOffset = CGSizeMake(0, -1);
    self.layer.shadowRadius = 2;

    self.titleLabel.textColor = [theme textPrimaryColor];
  } else {
    self.layer.borderWidth = 0;
    self.layer.shadowOpacity = 0;
    
    if (self.isHovered) {
      self.layer.backgroundColor = [[theme textPrimaryColor] colorWithAlphaComponent:0.05].CGColor;
      self.titleLabel.textColor = [theme textPrimaryColor];
    } else {
      self.layer.backgroundColor = [NSColor clearColor].CGColor;
      self.titleLabel.textColor = [theme textSecondaryColor];
    }
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
