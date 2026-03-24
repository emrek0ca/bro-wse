#import "MainWindowController.h"
#import "AmbientSoundManager.h"
#import "BlockedPageView.h"
#import "BookmarkManager.h"
#import "BookmarksWindowController.h"
#import "BreathingExerciseView.h"
#import "BrowserTab.h"
#import "DailyGoals.h"
#import "FindBar.h"
#import "FocusDashboardController.h"
#import "FocusEngine.h"
#import "FocusSessionManager.h"
#import "FocusStats.h"
#import "FocusTimerView.h"
#import "QuickNotesPanel.h"
#import "SettingsManager.h"
#import "SettingsWindowController.h"
#import "SiteBlocker.h"
#import "TabButton.h"
#import "ThemeManager.h"
#import <QuartzCore/QuartzCore.h>
#import <WebKit/WebKit.h>

static const CGFloat kChromeHeight = 94.0;
static const CGFloat kTabWidth = 150.0;
static const CGFloat kTabSpacing = 2.0;
static const CGFloat kAnimationDuration = 0.2;

@interface MainWindowController () <NSWindowDelegate>

// Chrome
@property(strong, nonatomic) NSView *chromeContainer;
@property(strong, nonatomic) NSTextField *addressBar;
@property(strong, nonatomic) NSButton *backButton;
@property(strong, nonatomic) NSButton *forwardButton;
@property(strong, nonatomic) NSButton *reloadButton;
@property(strong, nonatomic) NSButton *bookmarkButton;
@property(strong, nonatomic) NSScrollView *tabScrollView;
@property(strong, nonatomic) NSView *tabContainer;
@property(strong, nonatomic) NSButton *addTabButton;
@property(strong, nonatomic) NSView *contentView;
@property(strong, nonatomic) NSView *progressBar;
@property(strong, nonatomic) FindBar *findBar;

// Focus Sidebar (Vertical)
@property(strong, nonatomic) NSView *focusSidebar;
@property(strong, nonatomic) FocusTimerView *focusTimerView;
@property(strong, nonatomic) NSTextField *goalInput;
@property(strong, nonatomic) NSButton *timerButton;
@property(strong, nonatomic) NSTextField *timerLabel;
@property(strong, nonatomic) NSTextField *timerStateLabel;
@property(strong, nonatomic) NSButton *blockerButton;
@property(strong, nonatomic) NSButton *notesButton;
@property(strong, nonatomic) NSButton *breatheButton;
@property(strong, nonatomic) NSButton *soundButton;
@property(strong, nonatomic) NSButton *statsButton;
@property(strong, nonatomic) NSView *goalProgressView;
@property(strong, nonatomic) NSTextField *goalLabel;

// Ambient Sound Popover
@property(strong, nonatomic) NSPopover *soundPopover;
@property(strong, nonatomic) NSSlider *soundVolumeSlider;
@property(strong, nonatomic) NSPopUpButton *soundSelector;

// Tabs
@property(strong, nonatomic) NSMutableArray<BrowserTab *> *tabs;
@property(strong, nonatomic) NSMutableArray<TabButton *> *tabButtons;
@property(assign, nonatomic) NSInteger currentTabIndex;
@property(strong, nonatomic) NSMutableArray<NSString *> *recentlyClosedURLs;

// Constraints
@property(strong, nonatomic) NSLayoutConstraint *chromeHeightConstraint;
@property(strong, nonatomic) NSLayoutConstraint *contentTopConstraint;
@property(strong, nonatomic) NSLayoutConstraint *contentTopToWindowConstraint;
@property(strong, nonatomic)
    NSLayoutConstraint *contentRightToWindowConstraint; // New for sidebar
@property(strong, nonatomic)
    NSLayoutConstraint *contentRightToSidebarConstraint; // New for sidebar
@property(strong, nonatomic) NSLayoutConstraint *sidebarWidthConstraint;
@property(strong, nonatomic) NSLayoutConstraint *progressWidthConstraint;
@property(strong, nonatomic) NSLayoutConstraint *goalProgressWidthConstraint;

// Controllers
@property(strong, nonatomic) SettingsWindowController *settingsController;
@property(strong, nonatomic) BookmarksWindowController *bookmarksController;
@property(strong, nonatomic) FocusDashboardController *dashboardController;
@property(strong, nonatomic) QuickNotesPanel *notesPanel;
@property(strong, nonatomic) BreathingExerciseView *breathingView;
@property(strong, nonatomic) BlockedPageView *blockedPageView;

- (void)injectStatsIntoWebView:(WKWebView *)webView;
- (void)updateTheme;

@end

@implementation MainWindowController

- (instancetype)init {
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 1280, 820)
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                          NSWindowStyleMaskMiniaturizable |
                          NSWindowStyleMaskResizable |
                          NSWindowStyleMaskFullSizeContentView
                  backing:NSBackingStoreBuffered
                    defer:NO];
  window.title = @"Focus Browser";
  window.minSize = NSMakeSize(900, 600);
  window.titleVisibility = NSWindowTitleHidden;
  window.titlebarAppearsTransparent = YES;
  window.backgroundColor = [[ThemeManager sharedManager] backgroundColor];
  [window center];

  self = [super initWithWindow:window];
  if (self) {
    _tabs = [NSMutableArray array];
    _tabButtons = [NSMutableArray array];
    _recentlyClosedURLs = [NSMutableArray array];
    _currentTabIndex = -1;
    window.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTheme)
                                                 name:ThemeDidChangeNotification
                                               object:nil];

    [self setupUI];
    [self setupMenu];
    [self setupKeyboardShortcuts];

    // Legacy removed: setupTimerCallbacks
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(focusStateDidChange:)
               name:FocusStateDidChangeNotification
             object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(focusTimerDidTick:)
               name:FocusTimerDidTickNotification
             object:nil];

    [self updateTheme];
    [self updateTimerAppearance]; // Ensure UI matches Engine state on launch
  }
  return self;
}

#pragma mark - UI Setup

- (void)setupUI {
  NSView *mainView = self.window.contentView;
  mainView.wantsLayer = YES;

  // Chrome container
  self.chromeContainer = [[NSView alloc] init];
  self.chromeContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.chromeContainer.wantsLayer = YES;
  [mainView addSubview:self.chromeContainer];

  [self setupNavigationBar];
  [self setupTabBar];
  [self setupFocusSidebar];

  // Content view
  self.contentView = [[NSView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentView.wantsLayer = YES;
  [mainView addSubview:self.contentView];

  // Progress bar
  self.progressBar = [[NSView alloc] init];
  self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.progressBar.wantsLayer = YES;
  self.progressBar.layer.backgroundColor =
      [[NSColor controlAccentColor] CGColor];
  self.progressBar.alphaValue = 0;
  [self.chromeContainer addSubview:self.progressBar];

  // Find bar
  self.findBar = [[FindBar alloc] initWithFrame:NSZeroRect];
  self.findBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.findBar.hidden = YES;
  __weak typeof(self) weakSelf = self;
  self.findBar.onClose = ^{
    if (weakSelf.currentTabIndex >= 0 &&
        weakSelf.currentTabIndex < weakSelf.tabs.count) {
      [weakSelf.window
          makeFirstResponder:weakSelf.tabs[weakSelf.currentTabIndex].webView];
    }
  };
  [mainView addSubview:self.findBar];

  // Notes panel
  self.notesPanel = [[QuickNotesPanel alloc] initWithFrame:NSZeroRect];
  self.notesPanel.translatesAutoresizingMaskIntoConstraints = NO;
  self.notesPanel.hidden = YES;
  [mainView addSubview:self.notesPanel];

  // Breathing view
  self.breathingView = [[BreathingExerciseView alloc] initWithFrame:NSZeroRect];
  self.breathingView.translatesAutoresizingMaskIntoConstraints = NO;
  self.breathingView.hidden = YES;
  self.breathingView.onClose = ^{
    weakSelf.breathingView.hidden = YES;
  };
  [mainView addSubview:self.breathingView];

  // Blocked page view
  self.blockedPageView = [[BlockedPageView alloc] initWithFrame:NSZeroRect];
  self.blockedPageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.blockedPageView.hidden = YES;
  self.blockedPageView.onGoBack = ^{
    [weakSelf goBack:nil];
    weakSelf.blockedPageView.hidden = YES;
  };
  [mainView addSubview:self.blockedPageView];

  [self setupConstraints:mainView];

  [self updateGoalProgress];
}

- (void)setupNavigationBar {
  // Back button
  self.backButton = [self createToolButton:@"chevron.left"
                                  fallback:@"‹"
                                    action:@selector(goBack:)];
  self.backButton.toolTip = @"Back";
  [self.chromeContainer addSubview:self.backButton];

  // Forward button
  self.forwardButton = [self createToolButton:@"chevron.right"
                                     fallback:@"›"
                                       action:@selector(goForward:)];
  self.forwardButton.toolTip = @"Forward";
  [self.chromeContainer addSubview:self.forwardButton];

  // Reload button
  self.reloadButton = [self createToolButton:@"arrow.clockwise"
                                    fallback:@"↻"
                                      action:@selector(reload:)];
  self.reloadButton.toolTip = @"Reload";
  [self.chromeContainer addSubview:self.reloadButton];

  // Address bar
  self.addressBar = [[NSTextField alloc] init];
  self.addressBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.addressBar.placeholderString = @"Search or enter website";
  self.addressBar.font = [NSFont systemFontOfSize:13];
  self.addressBar.bezelStyle = NSTextFieldRoundedBezel;
  self.addressBar.focusRingType = NSFocusRingTypeNone;
  self.addressBar.target = self;
  self.addressBar.action = @selector(addressBarAction:);
  self.addressBar.cell.lineBreakMode = NSLineBreakByTruncatingTail;
  self.addressBar.wantsLayer = YES;
  self.addressBar.layer.cornerRadius = 6;
  [self.chromeContainer addSubview:self.addressBar];

  // Bookmark button
  self.bookmarkButton = [self createToolButton:@"bookmark"
                                      fallback:@"☆"
                                        action:@selector(toggleBookmark:)];
  self.bookmarkButton.toolTip = @"Bookmark";
  [self.chromeContainer addSubview:self.bookmarkButton];
}

- (void)setupTabBar {
  self.tabScrollView = [[NSScrollView alloc] init];
  self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabScrollView.hasHorizontalScroller = NO;
  self.tabScrollView.hasVerticalScroller = NO;
  self.tabScrollView.drawsBackground = NO;
  [self.chromeContainer addSubview:self.tabScrollView];

  self.tabContainer = [[NSView alloc] init];
  self.tabContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabScrollView.documentView = self.tabContainer;

  self.addTabButton = [self createToolButton:@"plus"
                                    fallback:@"+"
                                      action:@selector(newTab:)];
  self.addTabButton.toolTip = @"New Tab";
  [self.chromeContainer addSubview:self.addTabButton];
}

- (void)setupFocusSidebar {
  // Glassmorphism Sidebar
  NSVisualEffectView *effectView = [[NSVisualEffectView alloc] init];
  effectView.translatesAutoresizingMaskIntoConstraints = NO;
  effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
  effectView.material = NSVisualEffectMaterialSidebar;
  effectView.state = NSVisualEffectStateActive;
  self.focusSidebar = effectView;

  // Border for contrast
  self.focusSidebar.wantsLayer = YES;
  self.focusSidebar.layer.borderWidth = 1.0;
  self.focusSidebar.layer.borderColor = [[NSColor separatorColor] CGColor];

  [self.window.contentView addSubview:self.focusSidebar];

  // Main Stack View
  NSStackView *stackView = [[NSStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
  stackView.alignment = NSLayoutAttributeCenterX;
  stackView.spacing = 20;
  stackView.edgeInsets = NSEdgeInsetsMake(30, 10, 30, 10);
  [self.focusSidebar addSubview:stackView];

  [NSLayoutConstraint activateConstraints:@[
    [stackView.topAnchor constraintEqualToAnchor:self.focusSidebar.topAnchor],
    [stackView.leadingAnchor
        constraintEqualToAnchor:self.focusSidebar.leadingAnchor],
    [stackView.trailingAnchor
        constraintEqualToAnchor:self.focusSidebar.trailingAnchor],
  ]];

  // --- Daily Goal Input ---
  self.goalInput = [[NSTextField alloc] init];
  self.goalInput.translatesAutoresizingMaskIntoConstraints = NO;
  self.goalInput.placeholderString = @"Focus Goal?";
  self.goalInput.font = [NSFont systemFontOfSize:11];
  self.goalInput.alignment = NSTextAlignmentCenter;
  self.goalInput.bezelStyle = NSTextFieldRoundedBezel;
  self.goalInput.focusRingType = NSFocusRingTypeNone;
  self.goalInput.wantsLayer = YES;
  self.goalInput.layer.cornerRadius = 8;
  self.goalInput.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.1];
  self.goalInput.textColor = [NSColor labelColor];
  self.goalInput.drawsBackground = NO;
  [stackView addArrangedSubview:self.goalInput];
  [NSLayoutConstraint activateConstraints:@[
    [self.goalInput.widthAnchor constraintEqualToConstant:70],
    [self.goalInput.heightAnchor constraintEqualToConstant:24]
  ]];

  [stackView addArrangedSubview:[self createSeparator]];

  // --- Circular Timer Section ---
  self.focusTimerView =
      [[FocusTimerView alloc] initWithFrame:NSMakeRect(0, 0, 70, 70)];
  self.focusTimerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.focusTimerView.timeString = @"25:00";
  [stackView addArrangedSubview:self.focusTimerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.focusTimerView.widthAnchor constraintEqualToConstant:70],
    [self.focusTimerView.heightAnchor constraintEqualToConstant:70]
  ]];

  // Play/Action Button (Floating style below timer)
  self.timerButton = [self createSidebarButton:nil
                                         title:@"Start"
                                       toolTip:@"Start Focus Timer"
                                        action:@selector(toggleTimer:)];
  if (@available(macOS 11.0, *)) {
    self.timerButton.image = [NSImage imageWithSystemSymbolName:@"play.fill"
                                       accessibilityDescription:@"Start"];
    self.timerButton.imagePosition = NSImageOnly;
  }
  self.timerButton.title = @""; // Icon only
  [stackView addArrangedSubview:self.timerButton];

  [stackView addArrangedSubview:[self createSeparator]];

  // --- Tools Grid ---
  NSStackView *toolsStack = [[NSStackView alloc] init];
  toolsStack.orientation = NSUserInterfaceLayoutOrientationVertical;
  toolsStack.spacing = 16;
  toolsStack.alignment = NSLayoutAttributeCenterX;

  self.blockerButton = [self createSidebarButton:@"hand.raised"
                                           title:@"Block"
                                         toolTip:@"Toggle Site Blocker"
                                          action:@selector(toggleBlocker:)];
  self.notesButton = [self createSidebarButton:@"note.text"
                                         title:@"Notes"
                                       toolTip:@"Quick Notes"
                                        action:@selector(toggleNotes:)];
  self.breatheButton = [self createSidebarButton:@"lungs"
                                           title:@"Breathe"
                                         toolTip:@"Breathing Exercise"
                                          action:@selector(showBreathing:)];
  self.soundButton = [self createSidebarButton:@"speaker.wave.2"
                                         title:@"Sound"
                                       toolTip:@"Ambient Sounds"
                                        action:@selector(toggleSoundPopover:)];

  [toolsStack addArrangedSubview:self.blockerButton];
  [toolsStack addArrangedSubview:self.notesButton];
  [toolsStack addArrangedSubview:self.breatheButton];
  [toolsStack addArrangedSubview:self.soundButton];

  [stackView addArrangedSubview:toolsStack];

  [stackView addArrangedSubview:[self createSeparator]];

  // --- Stats & Bottom ---
  self.statsButton = [self createSidebarButton:@"chart.bar"
                                         title:@"Stats"
                                       toolTip:@"Focus Dashboard"
                                        action:@selector(showDashboard:)];
  [stackView addArrangedSubview:self.statsButton];

  // Flexible Application
  [stackView setHuggingPriority:NSLayoutPriorityDefaultLow
                 forOrientation:NSLayoutConstraintOrientationVertical];
}

- (NSButton *)createSidebarButton:(NSString *)symbolName
                            title:(NSString *)title
                          toolTip:(NSString *)toolTip
                           action:(SEL)action {
  NSButton *button = [[NSButton alloc] init];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.bezelStyle = NSBezelStyleRegularSquare;
  button.bordered = NO;
  button.toolTip = toolTip;
  button.target = self;
  button.action = action;

  if (@available(macOS 11.0, *)) {
    NSImage *image = [NSImage imageWithSystemSymbolName:symbolName
                               accessibilityDescription:title];
    NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration
        configurationWithPointSize:20
                            weight:NSFontWeightRegular];
    button.image = [image imageWithSymbolConfiguration:config];
  } else {
    button.title = title; // Fallback
  }

  button.imagePosition = NSImageAbove;
  button.title = title;
  button.font = [NSFont systemFontOfSize:10 weight:NSFontWeightMedium];
  button.imageScaling = NSImageScaleProportionallyDown;

  [NSLayoutConstraint activateConstraints:@[
    [button.widthAnchor constraintEqualToConstant:50],
    [button.heightAnchor constraintEqualToConstant:50]
  ]];

  return button;
}

- (void)toggleSoundPopover:(NSButton *)sender {
  if (!self.soundPopover) {
    [self setupAmbientSoundPopover];
  }
  if (self.soundPopover.shown) {
    [self.soundPopover close];
  } else {
    [self.soundPopover showRelativeToRect:sender.bounds
                                   ofView:sender
                            preferredEdge:NSRectEdgeMinX];
  }
}

- (void)setupAmbientSoundPopover {
  NSViewController *controller = [[NSViewController alloc] init];
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 150)];
  controller.view = view;

  NSStackView *stack = [[NSStackView alloc] init];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  stack.orientation = NSUserInterfaceLayoutOrientationVertical;
  stack.spacing = 12;
  stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);
  [view addSubview:stack];

  [NSLayoutConstraint activateConstraints:@[
    [stack.topAnchor constraintEqualToAnchor:view.topAnchor],
    [stack.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
    [stack.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
    [stack.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
  ]];

  // Label
  NSTextField *label = [self createLabel:@"Ambient Sound"
                                    size:13
                                  weight:NSFontWeightSemibold
                                    mono:NO];
  [stack addArrangedSubview:label];

  // Selector
  self.soundSelector =
      [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 24)
                                 pullsDown:NO];
  [self.soundSelector addItemsWithTitles:@[
    @"None", @"Rain", @"Forest", @"Ocean", @"Cafe", @"White Noise"
  ]];
  self.soundSelector.target = self;
  self.soundSelector.action = @selector(soundSelectionChanged:);
  [stack addArrangedSubview:self.soundSelector];

  // Volume Slider
  self.soundVolumeSlider = [[NSSlider alloc] init];
  self.soundVolumeSlider.minValue = 0.0;
  self.soundVolumeSlider.maxValue = 1.0;
  self.soundVolumeSlider.floatValue = 0.5;
  self.soundVolumeSlider.target = self;
  self.soundVolumeSlider.action = @selector(soundVolumeChanged:);
  [stack addArrangedSubview:self.soundVolumeSlider];

  self.soundPopover = [[NSPopover alloc] init];
  self.soundPopover.contentViewController = controller;
  self.soundPopover.behavior = NSPopoverBehaviorTransient;
}

- (void)soundSelectionChanged:(NSPopUpButton *)sender {
  NSInteger index = sender.indexOfSelectedItem;
  [[AmbientSoundManager sharedManager] playSound:index];
}

- (void)soundVolumeChanged:(NSSlider *)sender {
  [AmbientSoundManager sharedManager].volume = sender.floatValue;
}

- (NSButton *)createToolButton:(NSString *)symbolName
                      fallback:(NSString *)fallback
                        action:(SEL)action {
  NSButton *button = [[NSButton alloc] init];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.bezelStyle = NSBezelStyleTexturedRounded;
  button.bordered = NO;
  button.target = self;
  button.action = action;
  [button setButtonType:NSButtonTypeMomentaryPushIn];

  if (@available(macOS 11.0, *)) {
    NSImage *image = [NSImage imageWithSystemSymbolName:symbolName
                               accessibilityDescription:nil];
    if (image) {
      NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration
          configurationWithPointSize:14
                              weight:NSFontWeightRegular];
      button.image = [image imageWithSymbolConfiguration:config];
      button.imagePosition = NSImageOnly;
    } else {
      button.title = fallback;
      button.font = [NSFont systemFontOfSize:16 weight:NSFontWeightLight];
    }
  } else {
    button.title = fallback;
    button.font = [NSFont systemFontOfSize:16 weight:NSFontWeightLight];
  }

  return button;
}

- (NSButton *)createCompactButton:(NSString *)title action:(SEL)action {
  NSButton *button = [[NSButton alloc] init];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.title = title;
  button.bezelStyle = NSBezelStyleTexturedRounded;
  button.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
  button.target = self;
  button.action = action;
  button.wantsLayer = YES;
  button.layer.cornerRadius = 6;
  button.contentTintColor = [NSColor labelColor];
  [button setButtonType:NSButtonTypeMomentaryPushIn];
  return button;
}

- (NSTextField *)createLabel:(NSString *)text
                        size:(CGFloat)size
                      weight:(NSFontWeight)weight
                        mono:(BOOL)mono {
  NSTextField *label = [[NSTextField alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.stringValue = text;
  label.bordered = NO;
  label.editable = NO;
  label.selectable = NO;
  label.drawsBackground = NO;
  label.font = mono
                   ? [NSFont monospacedDigitSystemFontOfSize:size weight:weight]
                   : [NSFont systemFontOfSize:size weight:weight];
  label.textColor = [NSColor labelColor];
  return label;
}

- (NSView *)createSeparator {
  NSView *sep = [[NSView alloc] init];
  sep.translatesAutoresizingMaskIntoConstraints = NO;
  sep.wantsLayer = YES;
  sep.layer.backgroundColor = [[NSColor separatorColor] CGColor];
  return sep;
}

- (void)setupConstraints:(NSView *)mainView {
  // Chrome container
  [NSLayoutConstraint activateConstraints:@[
    [self.chromeContainer.leadingAnchor
        constraintEqualToAnchor:mainView.leadingAnchor],
    [self.chromeContainer.trailingAnchor
        constraintEqualToAnchor:mainView.trailingAnchor],
    [self.chromeContainer.topAnchor constraintEqualToAnchor:mainView.topAnchor],
  ]];

  self.chromeHeightConstraint = [self.chromeContainer.heightAnchor
      constraintEqualToConstant:kChromeHeight];
  self.chromeHeightConstraint.active = YES;

  // Navigation
  [NSLayoutConstraint activateConstraints:@[
    [self.backButton.leadingAnchor
        constraintEqualToAnchor:self.chromeContainer.leadingAnchor
                       constant:80],
    [self.backButton.topAnchor
        constraintEqualToAnchor:self.chromeContainer.topAnchor
                       constant:8],
    [self.backButton.widthAnchor constraintEqualToConstant:28],
    [self.backButton.heightAnchor constraintEqualToConstant:24],

    [self.forwardButton.leadingAnchor
        constraintEqualToAnchor:self.backButton.trailingAnchor
                       constant:2],
    [self.forwardButton.centerYAnchor
        constraintEqualToAnchor:self.backButton.centerYAnchor],
    [self.forwardButton.widthAnchor constraintEqualToConstant:28],
    [self.forwardButton.heightAnchor constraintEqualToConstant:24],

    [self.reloadButton.leadingAnchor
        constraintEqualToAnchor:self.forwardButton.trailingAnchor
                       constant:2],
    [self.reloadButton.centerYAnchor
        constraintEqualToAnchor:self.backButton.centerYAnchor],
    [self.reloadButton.widthAnchor constraintEqualToConstant:28],
    [self.reloadButton.heightAnchor constraintEqualToConstant:24],

    [self.addressBar.leadingAnchor
        constraintEqualToAnchor:self.reloadButton.trailingAnchor
                       constant:12],
    [self.addressBar.trailingAnchor
        constraintEqualToAnchor:self.bookmarkButton.leadingAnchor
                       constant:-8],
    [self.addressBar.centerYAnchor
        constraintEqualToAnchor:self.backButton.centerYAnchor],
    [self.addressBar.heightAnchor constraintEqualToConstant:28],

    [self.bookmarkButton.trailingAnchor
        constraintEqualToAnchor:self.chromeContainer.trailingAnchor
                       constant:-16],
    [self.bookmarkButton.centerYAnchor
        constraintEqualToAnchor:self.backButton.centerYAnchor],
    [self.bookmarkButton.widthAnchor constraintEqualToConstant:28],
    [self.bookmarkButton.heightAnchor constraintEqualToConstant:24],
  ]];

  // Tab bar
  [NSLayoutConstraint activateConstraints:@[
    [self.tabScrollView.leadingAnchor
        constraintEqualToAnchor:self.chromeContainer.leadingAnchor
                       constant:80],
    [self.tabScrollView.trailingAnchor
        constraintEqualToAnchor:self.addTabButton.leadingAnchor
                       constant:-8],
    [self.tabScrollView.topAnchor
        constraintEqualToAnchor:self.backButton.bottomAnchor
                       constant:6],
    [self.tabScrollView.heightAnchor constraintEqualToConstant:28],

    [self.addTabButton.trailingAnchor
        constraintEqualToAnchor:self.chromeContainer.trailingAnchor
                       constant:-16],
    [self.addTabButton.centerYAnchor
        constraintEqualToAnchor:self.tabScrollView.centerYAnchor],
    [self.addTabButton.widthAnchor constraintEqualToConstant:28],
    [self.addTabButton.heightAnchor constraintEqualToConstant:24],
  ]];

  // Focus Sidebar (right-aligned vertical)
  [NSLayoutConstraint activateConstraints:@[
    [self.focusSidebar.trailingAnchor
        constraintEqualToAnchor:mainView.trailingAnchor],
    [self.focusSidebar.topAnchor
        constraintEqualToAnchor:self.chromeContainer.bottomAnchor],
    [self.focusSidebar.bottomAnchor
        constraintEqualToAnchor:mainView.bottomAnchor],
    [self.focusSidebar.widthAnchor constraintEqualToConstant:90],
  ]];

  // Progress bar
  [NSLayoutConstraint activateConstraints:@[
    [self.progressBar.leadingAnchor
        constraintEqualToAnchor:self.chromeContainer.leadingAnchor],
    [self.progressBar.bottomAnchor
        constraintEqualToAnchor:self.chromeContainer.bottomAnchor],
    [self.progressBar.heightAnchor constraintEqualToConstant:2],
  ]];
  self.progressWidthConstraint =
      [self.progressBar.widthAnchor constraintEqualToConstant:0];
  self.progressWidthConstraint.active = YES;

  // Content view
  [NSLayoutConstraint activateConstraints:@[
    [self.contentView.leadingAnchor
        constraintEqualToAnchor:mainView.leadingAnchor],
    [self.contentView.trailingAnchor
        constraintEqualToAnchor:self.focusSidebar.leadingAnchor],
    [self.contentView.bottomAnchor
        constraintEqualToAnchor:mainView.bottomAnchor],
  ]];

  self.contentTopConstraint = [self.contentView.topAnchor
      constraintEqualToAnchor:self.chromeContainer.bottomAnchor];
  self.contentTopConstraint.active = YES;
  self.contentTopToWindowConstraint =
      [self.contentView.topAnchor constraintEqualToAnchor:mainView.topAnchor];
  self.contentTopToWindowConstraint.active = NO;

  // Find bar
  [NSLayoutConstraint activateConstraints:@[
    [self.findBar.topAnchor
        constraintEqualToAnchor:self.chromeContainer.bottomAnchor
                       constant:8],
    [self.findBar.trailingAnchor constraintEqualToAnchor:mainView.trailingAnchor
                                                constant:-16],
    [self.findBar.widthAnchor constraintEqualToConstant:320],
    [self.findBar.heightAnchor constraintEqualToConstant:36],
  ]];

  // Notes panel
  [NSLayoutConstraint activateConstraints:@[
    [self.notesPanel.trailingAnchor
        constraintEqualToAnchor:mainView.trailingAnchor],
    [self.notesPanel.topAnchor
        constraintEqualToAnchor:self.chromeContainer.bottomAnchor],
    [self.notesPanel.bottomAnchor
        constraintEqualToAnchor:mainView.bottomAnchor],
    [self.notesPanel.widthAnchor constraintEqualToConstant:300],
  ]];

  // Breathing view
  [NSLayoutConstraint activateConstraints:@[
    [self.breathingView.leadingAnchor
        constraintEqualToAnchor:mainView.leadingAnchor],
    [self.breathingView.trailingAnchor
        constraintEqualToAnchor:mainView.trailingAnchor],
    [self.breathingView.topAnchor constraintEqualToAnchor:mainView.topAnchor],
    [self.breathingView.bottomAnchor
        constraintEqualToAnchor:mainView.bottomAnchor],
  ]];

  // Blocked page
  [NSLayoutConstraint activateConstraints:@[
    [self.blockedPageView.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor],
    [self.blockedPageView.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor],
    [self.blockedPageView.topAnchor
        constraintEqualToAnchor:self.contentView.topAnchor],
    [self.blockedPageView.bottomAnchor
        constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];
}

#pragma mark - Menu

- (void)setupMenu {
  NSMenu *mainMenu = [[NSMenu alloc] init];

  // App menu
  NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
  NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Focus Browser"];
  [appMenu addItemWithTitle:@"About Focus Browser"
                     action:@selector(orderFrontStandardAboutPanel:)
              keyEquivalent:@""];
  [appMenu addItem:[NSMenuItem separatorItem]];
  NSMenuItem *prefsItem = [appMenu addItemWithTitle:@"Settings..."
                                             action:@selector(showSettings:)
                                      keyEquivalent:@","];
  prefsItem.target = self;
  [appMenu addItem:[NSMenuItem separatorItem]];
  [appMenu addItemWithTitle:@"Hide Focus Browser"
                     action:@selector(hide:)
              keyEquivalent:@"h"];
  [appMenu addItemWithTitle:@"Quit Focus Browser"
                     action:@selector(terminate:)
              keyEquivalent:@"q"];
  appMenuItem.submenu = appMenu;
  [mainMenu addItem:appMenuItem];

  // File menu
  NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
  NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
  [[fileMenu addItemWithTitle:@"New Tab"
                       action:@selector(newTab:)
                keyEquivalent:@"t"] setTarget:self];
  [[fileMenu addItemWithTitle:@"Close Tab"
                       action:@selector(closeCurrentTab:)
                keyEquivalent:@"w"] setTarget:self];
  NSMenuItem *reopenItem =
      [fileMenu addItemWithTitle:@"Reopen Closed Tab"
                          action:@selector(reopenClosedTab:)
                   keyEquivalent:@"t"];
  reopenItem.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  reopenItem.target = self;
  fileMenuItem.submenu = fileMenu;
  [mainMenu addItem:fileMenuItem];

  // Edit menu
  NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
  [editMenu addItemWithTitle:@"Undo"
                      action:@selector(undo:)
               keyEquivalent:@"z"];
  [editMenu addItemWithTitle:@"Redo"
                      action:@selector(redo:)
               keyEquivalent:@"Z"];
  [editMenu addItem:[NSMenuItem separatorItem]];
  [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
  [editMenu addItemWithTitle:@"Copy"
                      action:@selector(copy:)
               keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Paste"
                      action:@selector(paste:)
               keyEquivalent:@"v"];
  [editMenu addItemWithTitle:@"Select All"
                      action:@selector(selectAll:)
               keyEquivalent:@"a"];
  [editMenu addItem:[NSMenuItem separatorItem]];
  [[editMenu addItemWithTitle:@"Find..."
                       action:@selector(showFindBar:)
                keyEquivalent:@"f"] setTarget:self];
  editMenuItem.submenu = editMenu;
  [mainMenu addItem:editMenuItem];

  // View menu
  NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
  NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
  [[viewMenu addItemWithTitle:@"Toggle Focus Mode"
                       action:@selector(toggleFocusMode:)
                keyEquivalent:@"\\"] setTarget:self];
  NSMenuItem *readerItem =
      [viewMenu addItemWithTitle:@"Reader Mode"
                          action:@selector(toggleReaderMode:)
                   keyEquivalent:@"r"];
  readerItem.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  readerItem.target = self;
  [viewMenu addItem:[NSMenuItem separatorItem]];
  [[viewMenu addItemWithTitle:@"Reload"
                       action:@selector(reload:)
                keyEquivalent:@"r"] setTarget:self];
  viewMenuItem.submenu = viewMenu;
  [mainMenu addItem:viewMenuItem];

  // Focus menu
  NSMenuItem *focusMenuItem = [[NSMenuItem alloc] init];
  NSMenu *focusMenu = [[NSMenu alloc] initWithTitle:@"Focus"];
  [[focusMenu addItemWithTitle:@"Start/Pause Timer"
                        action:@selector(toggleTimer:)
                 keyEquivalent:@"p"] setTarget:self];
  NSMenuItem *blockerItem =
      [focusMenu addItemWithTitle:@"Toggle Site Blocker"
                           action:@selector(toggleBlocker:)
                    keyEquivalent:@"b"];
  blockerItem.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  blockerItem.target = self;
  [focusMenu addItem:[NSMenuItem separatorItem]];
  NSMenuItem *notesItem = [focusMenu addItemWithTitle:@"Quick Notes"
                                               action:@selector(toggleNotes:)
                                        keyEquivalent:@"n"];
  notesItem.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  notesItem.target = self;
  [[focusMenu addItemWithTitle:@"Breathing Exercise"
                        action:@selector(showBreathing:)
                 keyEquivalent:@""] setTarget:self];
  [focusMenu addItem:[NSMenuItem separatorItem]];
  NSMenuItem *dashItem = [focusMenu addItemWithTitle:@"Focus Dashboard"
                                              action:@selector(showDashboard:)
                                       keyEquivalent:@"d"];
  dashItem.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  dashItem.target = self;
  focusMenuItem.submenu = focusMenu;
  [mainMenu addItem:focusMenuItem];

  // Window menu
  NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
  NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
  [[windowMenu addItemWithTitle:@"Focus Address Bar"
                         action:@selector(focusAddressBar:)
                  keyEquivalent:@"l"] setTarget:self];
  [windowMenu addItem:[NSMenuItem separatorItem]];
  NSMenuItem *nextTab = [windowMenu addItemWithTitle:@"Next Tab"
                                              action:@selector(selectNextTab:)
                                       keyEquivalent:@"]"];
  nextTab.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  nextTab.target = self;
  NSMenuItem *prevTab =
      [windowMenu addItemWithTitle:@"Previous Tab"
                            action:@selector(selectPreviousTab:)
                     keyEquivalent:@"["];
  prevTab.keyEquivalentModifierMask =
      NSEventModifierFlagCommand | NSEventModifierFlagShift;
  prevTab.target = self;
  [windowMenu addItem:[NSMenuItem separatorItem]];
  [windowMenu addItemWithTitle:@"Minimize"
                        action:@selector(performMiniaturize:)
                 keyEquivalent:@"m"];
  windowMenuItem.submenu = windowMenu;
  [mainMenu addItem:windowMenuItem];

  [NSApp setMainMenu:mainMenu];
}

- (void)setupKeyboardShortcuts {
  [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                        handler:^NSEvent *(NSEvent *event) {
                                          if (event.keyCode == 53) { // Escape
                                            if (!self.breathingView.hidden) {
                                              self.breathingView.hidden = YES;
                                              [self.breathingView stopExercise];
                                              return nil;
                                            }
                                            if (!self.blockedPageView.hidden) {
                                              [self goBack:nil];
                                              self.blockedPageView.hidden = YES;
                                              return nil;
                                            }
                                            if ([self.notesPanel isVisible]) {
                                              [self.notesPanel hide];
                                              return nil;
                                            }
                                            if (!self.findBar.hidden) {
                                              [self.findBar hide];
                                              return nil;
                                            }
                                            if ([FocusEngine sharedEngine]
                                                    .isZenModeActive) {
                                              // Cannot disable via escape in
                                              // strict mode
                                              return nil;
                                            }
                                          }
                                          return event;
                                        }];
}

#pragma mark - Focus Engine Listeners

- (void)focusStateDidChange:(NSNotification *)note {
  [self updateTimerAppearance];
  [self updateBlockerAppearance];

  // Auto-hide UI in Flow state (Zen Mode)
  BOOL zenMode = [[FocusEngine sharedEngine] isZenModeActive];
  [self setFocusModeEnabled:zenMode];

  // Refresh stats if session ended
  if ([FocusEngine sharedEngine].state == FocusStateIdle) {
    [self updateGoalProgress];
  }
}

- (void)focusTimerDidTick:(NSNotification *)note {
  NSTimeInterval remaining = [FocusEngine sharedEngine].timeRemaining;
  NSInteger minutes = (NSInteger)remaining / 60;
  NSInteger seconds = (NSInteger)remaining % 60;
  NSString *timeStr =
      [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];

  if (self.timerLabel)
    self.timerLabel.stringValue = timeStr;
  self.focusTimerView.timeString = timeStr;

  // Calculate progress (simplified, assuming 25 min default for now)
  CGFloat total = 25.0 * 60.0;
  if ([FocusEngine sharedEngine].state == FocusStateBreak)
    total = 5.0 * 60.0;

  self.focusTimerView.progress = 1.0 - (remaining / total);
}

#pragma mark - Tab Management

- (void)createNewTabWithURL:(NSString *)urlString {
  if ([urlString isEqualToString:@"focus://start"]) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"start"
                                                     ofType:@"html"];
    if (path) {
      urlString = [NSURL fileURLWithPath:path].absoluteString;
    }
  }

  BrowserTab *tab = [[BrowserTab alloc] initWithURLString:urlString];
  [self.tabs addObject:tab];
  [self createTabButton:tab];
  [self selectTabAtIndex:self.tabs.count - 1];

  __weak typeof(self) weakSelf = self;
  tab.progressHandler = ^(double progress) {
    [weakSelf updateProgress:progress];
  };
  __weak BrowserTab *weakTab = tab;
  tab.completionHandler = ^{
    [weakSelf injectStatsIntoWebView:weakTab.webView];
  };
}

- (void)restoreTabsWithURLs:(NSArray<NSString *> *)urls {
  for (NSString *url in urls) {
    NSString *finalURL = url;
    if ([url isEqualToString:@"focus://start"]) {
      NSString *path = [[NSBundle mainBundle] pathForResource:@"start"
                                                       ofType:@"html"];
      if (path)
        finalURL = [NSURL fileURLWithPath:path].absoluteString;
    }
    BrowserTab *tab = [[BrowserTab alloc] initWithURLString:finalURL];
    [self.tabs addObject:tab];
    [self createTabButton:tab];

    __weak typeof(self) weakSelf = self;
    tab.progressHandler = ^(double progress) {
      [weakSelf updateProgress:progress];
    };
    __weak BrowserTab *weakTab = tab;
    tab.completionHandler = ^{
      [weakSelf injectStatsIntoWebView:weakTab.webView];
    };
  }
  if (self.tabs.count > 0) {
    [self selectTabAtIndex:0];
  }
}

- (void)createTabButton:(BrowserTab *)tab {
  TabButton *button = [[TabButton alloc] initWithFrame:NSZeroRect];
  button.title = tab.title;

  __weak typeof(self) weakSelf = self;
  __weak TabButton *weakButton = button;
  __weak BrowserTab *weakTab = tab;

  button.onSelect = ^{
    NSInteger index = [weakSelf.tabButtons indexOfObject:weakButton];
    if (index != NSNotFound)
      [weakSelf selectTabAtIndex:index];
  };

  button.onClose = ^{
    NSInteger index = [weakSelf.tabButtons indexOfObject:weakButton];
    if (index != NSNotFound)
      [weakSelf closeTabAtIndex:index];
  };

  tab.titleChangeHandler = ^(NSString *newTitle) {
    weakButton.title = newTitle;
  };

  tab.urlChangeHandler = ^(NSString *newURL) {
    if (weakSelf.currentTabIndex >= 0 &&
        weakSelf.currentTabIndex < weakSelf.tabs.count &&
        weakSelf.tabs[weakSelf.currentTabIndex] == weakTab) {
      weakSelf.addressBar.stringValue = newURL ?: @"";
      [weakSelf updateBookmarkButton];
      [weakSelf checkBlockedSite:newURL];
    }
  };

  [self.tabContainer addSubview:button];
  [self.tabButtons addObject:button];
  [button updateAppearance];
  [self layoutTabButtons];
}

- (void)layoutTabButtons {
  CGFloat x = 0;
  for (TabButton *button in self.tabButtons) {
    button.frame = NSMakeRect(x, 0, kTabWidth, 26);
    x += kTabWidth + kTabSpacing;
  }
  self.tabContainer.frame = NSMakeRect(0, 0, x, 26);
}

- (void)selectTabAtIndex:(NSInteger)index {
  if (index < 0 || index >= self.tabs.count)
    return;

  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    [self.tabs[self.currentTabIndex].webView removeFromSuperview];
    if (self.currentTabIndex < self.tabButtons.count) {
      self.tabButtons[self.currentTabIndex].isSelected = NO;
    }
  }

  self.currentTabIndex = index;
  BrowserTab *tab = self.tabs[index];
  tab.webView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:tab.webView
                    positioned:NSWindowBelow
                    relativeTo:self.blockedPageView];

  [NSLayoutConstraint activateConstraints:@[
    [tab.webView.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor],
    [tab.webView.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor],
    [tab.webView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [tab.webView.bottomAnchor
        constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  if (index < self.tabButtons.count)
    self.tabButtons[index].isSelected = YES;
  self.addressBar.stringValue = tab.webView.URL.absoluteString ?: @"";
  self.findBar.webView = tab.webView;
  [self updateNavigationButtons];
  [self updateBookmarkButton];
  [self checkBlockedSite:tab.webView.URL.absoluteString];
}

- (void)closeTabAtIndex:(NSInteger)index {
  if (self.tabs.count <= 1 || index < 0 || index >= self.tabs.count)
    return;

  BrowserTab *tab = self.tabs[index];
  NSString *url = tab.webView.URL.absoluteString;
  if (url) {
    [self.recentlyClosedURLs insertObject:url atIndex:0];
    if (self.recentlyClosedURLs.count > 10)
      [self.recentlyClosedURLs removeLastObject];
  }

  [tab.webView removeFromSuperview];
  [self.tabs removeObjectAtIndex:index];
  [self.tabButtons[index] removeFromSuperview];
  [self.tabButtons removeObjectAtIndex:index];
  [self layoutTabButtons];

  NSInteger newIndex = index >= self.tabs.count ? self.tabs.count - 1 : index;
  self.currentTabIndex = -1;
  [self selectTabAtIndex:newIndex];
}

- (NSArray<NSString *> *)allTabURLs {
  NSMutableArray *urls = [NSMutableArray array];
  for (BrowserTab *tab in self.tabs) {
    NSString *url = tab.webView.URL.absoluteString;
    if ([url hasPrefix:@"file://"] && [url containsString:@"start.html"]) {
      [urls addObject:@"focus://start"];
    } else if (url) {
      [urls addObject:url];
    }
  }
  return urls;
}

- (void)navigateToURL:(NSString *)urlString {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url)
      [self.tabs[self.currentTabIndex] loadURL:url];
  }
}

#pragma mark - Site Blocking

- (void)checkBlockedSite:(NSString *)urlString {
  if (!urlString) {
    self.blockedPageView.hidden = YES;
    return;
  }

  NSURL *url = [NSURL URLWithString:urlString];
  if ([[SiteBlocker sharedBlocker] shouldBlockURL:url]) {
    self.blockedPageView.blockedDomain = url.host;
    self.blockedPageView.hidden = NO;
    [[FocusStats sharedStats] incrementBlockedSites];
    [self updateGoalProgress];
  } else {
    self.blockedPageView.hidden = YES;
  }
}

#pragma mark - Actions

- (void)addressBarAction:(NSTextField *)sender {
  NSString *input = [sender.stringValue
      stringByTrimmingCharactersInSet:[NSCharacterSet
                                          whitespaceAndNewlineCharacterSet]];
  if (input.length == 0)
    return;

  if (![input hasPrefix:@"http://"] && ![input hasPrefix:@"https://"]) {
    if ([input containsString:@"."] && ![input containsString:@" "]) {
      input = [@"https://" stringByAppendingString:input];
    } else {
      input = [[SettingsManager sharedManager] searchURLForQuery:input];
    }
  }

  NSURL *url = [NSURL URLWithString:input];
  if (url && self.currentTabIndex >= 0 &&
      self.currentTabIndex < self.tabs.count) {
    [self.tabs[self.currentTabIndex] loadURL:url];
  }
  [self.window makeFirstResponder:self.tabs[self.currentTabIndex].webView];
}

- (void)goBack:(id)sender {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    self.blockedPageView.hidden = YES;
    [self.tabs[self.currentTabIndex].webView goBack];
  }
}

- (void)goForward:(id)sender {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    [self.tabs[self.currentTabIndex].webView goForward];
  }
}

- (void)reload:(id)sender {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    [self.tabs[self.currentTabIndex].webView reload];
  }
}

- (void)newTab:(id)sender {
  [self createNewTabWithURL:[SettingsManager sharedManager].homepage];
}

- (void)closeCurrentTab:(id)sender {
  [self closeTabAtIndex:self.currentTabIndex];
}

- (void)reopenClosedTab:(id)sender {
  if (self.recentlyClosedURLs.count == 0)
    return;
  NSString *url = self.recentlyClosedURLs.firstObject;
  [self.recentlyClosedURLs removeObjectAtIndex:0];
  [self createNewTabWithURL:url];
}

- (void)selectNextTab:(id)sender {
  if (self.tabs.count <= 1)
    return;
  [self selectTabAtIndex:(self.currentTabIndex + 1) % self.tabs.count];
}

- (void)selectPreviousTab:(id)sender {
  if (self.tabs.count <= 1)
    return;
  NSInteger prev = self.currentTabIndex - 1;
  [self selectTabAtIndex:prev < 0 ? self.tabs.count - 1 : prev];
}

- (void)toggleFocusMode:(id)sender {
  // No manual toggle anymore
  // [[FocusModeManager sharedManager] toggle];
}

- (void)focusAddressBar:(id)sender {
  if ([FocusEngine sharedEngine].isZenModeActive) {
    // Optional: Temporarily reveal or deny?
    // For strict compliance: Deny or require pause.
  }
  [self.window makeFirstResponder:self.addressBar];
  [self.addressBar selectText:nil];
}

- (void)showFindBar:(id)sender {
  if (self.findBar.hidden)
    [self.findBar show];
  [self.findBar focus];
}

- (void)toggleReaderMode:(id)sender {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    NSString *js =
        @"(function(){var "
        @"a=document.querySelector('article')||document.querySelector('main')||"
        @"document.body;var c=a.innerHTML;var "
        @"t=document.title;document.body.innerHTML='<div "
        @"style=\"max-width:680px;margin:50px "
        @"auto;padding:24px;font-family:-apple-system,system-ui,sans-serif;"
        @"font-size:18px;line-height:1.7;color:#1d1d1f;\"><h1 "
        @"style=\"font-size:32px;font-weight:600;margin-bottom:24px;\">'+t+'</"
        @"h1>'+c+'</div>';document.body.style.background='#fbfbfd';})();";
    [self.tabs[self.currentTabIndex].webView evaluateJavaScript:js
                                              completionHandler:nil];
  }
}

- (void)toggleBookmark:(id)sender {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    BrowserTab *tab = self.tabs[self.currentTabIndex];
    NSString *url = tab.webView.URL.absoluteString;

    if ([[BookmarkManager sharedManager] isBookmarked:url]) {
      for (Bookmark *b in [[BookmarkManager sharedManager] allBookmarks]) {
        if ([b.url isEqualToString:url]) {
          [[BookmarkManager sharedManager] removeBookmark:b];
          break;
        }
      }
    } else {
      [[BookmarkManager sharedManager] addBookmarkWithTitle:tab.title url:url];
    }
    [self updateBookmarkButton];
  }
}

- (void)showBookmarks:(id)sender {
  if (!self.bookmarksController) {
    self.bookmarksController = [[BookmarksWindowController alloc] init];
    __weak typeof(self) weakSelf = self;
    self.bookmarksController.onBookmarkSelected = ^(NSString *url) {
      [weakSelf navigateToURL:url];
    };
  }
  [self.bookmarksController showWindow:nil];
}

- (void)showSettings:(id)sender {
  if (!self.settingsController)
    self.settingsController = [[SettingsWindowController alloc] init];
  [self.settingsController showWindow:nil];
}

#pragma mark - Focus Features

- (void)toggleTimer:(id)sender {
  FocusEngine *engine = [FocusEngine sharedEngine];

  // Visual feedback animation
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.05;
        self.timerButton.animator.alphaValue = 0.5;
      }
      completionHandler:^{
        [NSAnimationContext
            runAnimationGroup:^(NSAnimationContext *context) {
              context.duration = 0.1;
              self.timerButton.animator.alphaValue = 1.0;
            }
            completionHandler:nil];
      }];

  if (engine.state == FocusStateIdle) {
    [engine startFlowSession:25 strict:YES];
  } else if (engine.state == FocusStateFlow) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Abandon Session?";
    alert.informativeText =
        @"Stopping now will mark this session as incomplete.";
    [alert addButtonWithTitle:@"Resume"];
    [alert addButtonWithTitle:@"Abandon"];
    if ([alert runModal] == NSAlertSecondButtonReturn) {
      [engine endSession];
    }
  } else {
    [engine endSession];
  }
}

- (void)updateTimerAppearance {
  FocusEngine *engine = [FocusEngine sharedEngine];

  NSColor *stateColor = [NSColor labelColor];
  NSColor *sidebarBorderColor =
      [[NSColor separatorColor] colorWithAlphaComponent:0.5];
  CGFloat borderWidth = 1.0;
  NSString *btnIcon = @"play.fill";

  // Update Progress
  if (engine.state == FocusStateFlow || engine.state == FocusStateBreak) {
    CGFloat total = (engine.state == FocusStateFlow) ? 25.0 * 60.0 : 5.0 * 60.0;
    CGFloat current = engine.timeRemaining;
    self.focusTimerView.progress = 1.0 - (current / total);
  } else {
    self.focusTimerView.progress = 1.0;
  }

  switch (engine.state) {
  case FocusStateIdle:
    btnIcon = @"play.fill";
    stateColor = [NSColor systemGreenColor];
    self.focusTimerView.timeString = @"25:00";
    self.focusTimerView.progress = 1.0;
    [self.focusTimerView stopPulseAnimation];
    break;
  case FocusStateFlow:
    btnIcon = @"pause.fill";
    stateColor = [NSColor systemGreenColor];
    sidebarBorderColor = [NSColor systemGreenColor];
    borderWidth = 2.0;
    [self.focusTimerView startPulseAnimation];
    break;
  case FocusStateBreak:
    btnIcon = @"forward.fill";
    stateColor = [NSColor systemBlueColor];
    sidebarBorderColor = [NSColor systemBlueColor];
    borderWidth = 2.0;
    [self.focusTimerView startPulseAnimation];
    break;
  }

  self.focusTimerView.progressColor = stateColor;
  if (@available(macOS 11.0, *)) {
    self.timerButton.image = [NSImage imageWithSystemSymbolName:btnIcon
                                       accessibilityDescription:nil];
  }

  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.focusSidebar.layer.borderColor = sidebarBorderColor.CGColor;
        self.focusSidebar.layer.borderWidth = borderWidth;
      }
      completionHandler:nil];
}

- (void)toggleBlocker:(id)sender {
  FocusEngine *engine = [FocusEngine sharedEngine];
  SiteBlocker *blocker = [SiteBlocker sharedBlocker];

  if (engine.state == FocusStateFlow) {
    // Cannot disable during flow - give feedback
    NSBeep();

    // Flash the button to indicate it's locked
    [NSAnimationContext
        runAnimationGroup:^(NSAnimationContext *context) {
          context.duration = 0.1;
          self.blockerButton.animator.alphaValue = 0.3;
        }
        completionHandler:^{
          [NSAnimationContext
              runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.1;
                self.blockerButton.animator.alphaValue = 1.0;
              }
              completionHandler:nil];
        }];
  } else {
    // Toggle blocker in idle/break mode
    blocker.isEnabled = !blocker.isEnabled;
    [self updateBlockerAppearance];
  }
}

- (void)updateBlockerAppearance {
  BOOL enabled = [SiteBlocker sharedBlocker].isEnabled;
  self.blockerButton.title = enabled ? @"Block On" : @"Block";

  if (enabled) {
    self.blockerButton.contentTintColor = [NSColor systemGreenColor];
  } else {
    self.blockerButton.contentTintColor = [NSColor secondaryLabelColor];
  }
}

- (void)toggleNotes:(id)sender {
  [self.notesPanel toggle];
}
- (void)showBreathing:(id)sender {
  self.breathingView.hidden = NO;
}

- (void)showDashboard:(id)sender {
  if (!self.dashboardController)
    self.dashboardController = [[FocusDashboardController alloc] init];
  [self.dashboardController refresh];
  [self.dashboardController showWindow:nil];
}

- (void)updateGoalProgress {
  [[DailyGoals sharedGoals] refresh];
  CGFloat progress = [[DailyGoals sharedGoals] focusProgress];
  self.goalProgressWidthConstraint.constant = 50 * progress;
  self.goalLabel.stringValue =
      [NSString stringWithFormat:@"%.0f%%", progress * 100];

  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    [self injectStatsIntoWebView:self.tabs[self.currentTabIndex].webView];
  }
}

- (void)setFocusModeEnabled:(BOOL)enabled {
  if (!self.findBar.hidden)
    [self.findBar hide];
  if ([self.notesPanel isVisible])
    [self.notesPanel hide];

  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        self.chromeContainer.animator.alphaValue = enabled ? 0 : 1;
        if (enabled) {
          self.contentTopConstraint.active = NO;
          self.contentTopToWindowConstraint.active = YES;
        } else {
          self.contentTopToWindowConstraint.active = NO;
          self.contentTopConstraint.active = YES;
        }
      }
      completionHandler:^{
        self.chromeContainer.hidden = enabled;
      }];
}

- (void)updateNavigationButtons {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    WKWebView *webView = self.tabs[self.currentTabIndex].webView;
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
  }
}

- (void)updateBookmarkButton {
  if (self.currentTabIndex >= 0 && self.currentTabIndex < self.tabs.count) {
    NSString *url = self.tabs[self.currentTabIndex].webView.URL.absoluteString;
    BOOL bookmarked = [[BookmarkManager sharedManager] isBookmarked:url];
    self.bookmarkButton.contentTintColor =
        bookmarked ? [NSColor systemYellowColor] : nil;
  }
}

- (void)updateProgress:(double)progress {
  if (progress > 0 && progress < 1) {
    self.progressBar.alphaValue = 1;
    self.progressWidthConstraint.constant =
        self.chromeContainer.bounds.size.width * progress;
  } else {
    [NSAnimationContext
        runAnimationGroup:^(NSAnimationContext *context) {
          context.duration = 0.2;
          self.progressBar.animator.alphaValue = 0;
        }
        completionHandler:^{
          self.progressWidthConstraint.constant = 0;
        }];
  }
}

#pragma mark - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
  [self updateNavigationButtons];
  [self updateGoalProgress];
}

- (void)injectStatsIntoWebView:(WKWebView *)webView {
  if (!webView.URL.isFileURL ||
      ![webView.URL.absoluteString containsString:@"start.html"])
    return;

  DailyStats *today = [[FocusStats sharedStats] todayStats];
  // Calculate score logic remains in FocusStats for now
  CGFloat score = [[FocusStats sharedStats] calculateFocusScore];
  NSString *desc = [[FocusStats sharedStats] focusScoreDescription];

  NSString *json = [NSString
      stringWithFormat:@"{"
                        "\"score\": %.0f,"
                        "\"scoreDescription\": \"%@\","
                        "\"pomodoros\": %ld,"
                        "\"blocked\": %ld,"
                        "\"focusMinutes\": %ld"
                        "}",
                       score, desc, (long)today.pomodorosCompleted,
                       (long)today.sitesBlocked, (long)today.focusMinutes];

  NSString *js = [NSString
      stringWithFormat:@"window.updateStats && window.updateStats(%@);", json];
  [webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark - Theme

- (void)updateTheme {
  NSLog(@"DEBUG: updateTheme called. DarkMode: %d",
        [ThemeManager sharedManager].isDarkMode);
  ThemeManager *theme = [ThemeManager sharedManager];

  // Window background
  self.window.backgroundColor = [theme backgroundColor];

  // Chrome
  self.chromeContainer.layer.backgroundColor = [theme surfaceColor].CGColor;

  // Focus Sidebar - Glassmorphism
  self.focusSidebar.layer.borderColor = [theme borderColor].CGColor;
  // Do NOT set background color for NSVisualEffectView, it handles itself.
  if (![self.focusSidebar isKindOfClass:[NSVisualEffectView class]]) {
    self.focusSidebar.layer.backgroundColor =
        [theme elevatedSurfaceColor].CGColor;
  }

  // Address Bar
  self.addressBar.backgroundColor = [theme elevatedSurfaceColor];
  self.addressBar.textColor = [theme textPrimaryColor];

  if (self.timerLabel) {
    self.timerLabel.textColor = [theme textPrimaryColor];
  }

  // Refresh Tabs
  for (TabButton *btn in self.tabButtons) {
    [btn updateAppearance];
  }
}

@end
