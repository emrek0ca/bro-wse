#import "FocusDashboardController.h"
#import "FocusStats.h"

@interface FocusDashboardController ()

@property(strong, nonatomic) NSTextField *scoreLabel;
@property(strong, nonatomic) NSTextField *scoreDescLabel;
@property(strong, nonatomic) NSView *scoreCircle;
@property(strong, nonatomic) NSTextField *pomodorosLabel;
@property(strong, nonatomic) NSTextField *focusTimeLabel;
@property(strong, nonatomic) NSTextField *blockedLabel;
@property(strong, nonatomic) NSView *weeklyChartView;

@end

@implementation FocusDashboardController

- (instancetype)init {
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 500, 450)
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                  backing:NSBackingStoreBuffered
                    defer:NO];
  window.title = @"Focus Dashboard";
  [window center];

  self = [super initWithWindow:window];
  if (self) {
    [self setupUI];
    [self refresh];
  }
  return self;
}

- (void)setupUI {
  NSView *content = self.window.contentView;
  content.wantsLayer = YES;

  // Score circle
  self.scoreCircle =
      [[NSView alloc] initWithFrame:NSMakeRect(175, 300, 150, 150)];
  self.scoreCircle.wantsLayer = YES;
  self.scoreCircle.layer.cornerRadius = 75;
  self.scoreCircle.layer.borderWidth = 8;
  self.scoreCircle.layer.borderColor = [[NSColor controlAccentColor] CGColor];
  self.scoreCircle.layer.backgroundColor =
      [[NSColor controlAccentColor] colorWithAlphaComponent:0.1].CGColor;
  [content addSubview:self.scoreCircle];

  // Score number
  self.scoreLabel =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 55, 150, 50)];
  self.scoreLabel.bordered = NO;
  self.scoreLabel.editable = NO;
  self.scoreLabel.selectable = NO;
  self.scoreLabel.drawsBackground = NO;
  self.scoreLabel.font = [NSFont systemFontOfSize:42 weight:NSFontWeightBold];
  self.scoreLabel.textColor = [NSColor controlAccentColor];
  self.scoreLabel.alignment = NSTextAlignmentCenter;
  self.scoreLabel.stringValue = @"0";
  [self.scoreCircle addSubview:self.scoreLabel];

  // Score description
  self.scoreDescLabel =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 35, 150, 20)];
  self.scoreDescLabel.bordered = NO;
  self.scoreDescLabel.editable = NO;
  self.scoreDescLabel.selectable = NO;
  self.scoreDescLabel.drawsBackground = NO;
  self.scoreDescLabel.font = [NSFont systemFontOfSize:11];
  self.scoreDescLabel.textColor = [NSColor secondaryLabelColor];
  self.scoreDescLabel.alignment = NSTextAlignmentCenter;
  self.scoreDescLabel.stringValue = @"Focus Score";
  [self.scoreCircle addSubview:self.scoreDescLabel];

  // Stats section
  CGFloat statY = 230;
  CGFloat statHeight = 50;

  // Pomodoros
  NSView *pomoView =
      [self createStatViewWithFrame:NSMakeRect(30, statY, 130, statHeight)];
  [content addSubview:pomoView];

  self.pomodorosLabel =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, 130, 30)];
  [self configureStatLabel:self.pomodorosLabel large:YES];
  self.pomodorosLabel.stringValue = @"0";
  [pomoView addSubview:self.pomodorosLabel];

  NSTextField *pomoTitle =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 130, 20)];
  [self configureStatLabel:pomoTitle large:NO];
  pomoTitle.stringValue = @"Pomodoros";
  [pomoView addSubview:pomoTitle];

  // Focus Time
  NSView *timeView =
      [self createStatViewWithFrame:NSMakeRect(185, statY, 130, statHeight)];
  [content addSubview:timeView];

  self.focusTimeLabel =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, 130, 30)];
  [self configureStatLabel:self.focusTimeLabel large:YES];
  self.focusTimeLabel.stringValue = @"0m";
  [timeView addSubview:self.focusTimeLabel];

  NSTextField *timeTitle =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 130, 20)];
  [self configureStatLabel:timeTitle large:NO];
  timeTitle.stringValue = @"Focus Time";
  [timeView addSubview:timeTitle];

  // Blocked Sites
  NSView *blockedView =
      [self createStatViewWithFrame:NSMakeRect(340, statY, 130, statHeight)];
  [content addSubview:blockedView];

  self.blockedLabel =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, 130, 30)];
  [self configureStatLabel:self.blockedLabel large:YES];
  self.blockedLabel.stringValue = @"0";
  [blockedView addSubview:self.blockedLabel];

  NSTextField *blockedTitle =
      [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 130, 20)];
  [self configureStatLabel:blockedTitle large:NO];
  blockedTitle.stringValue = @"Sites Blocked";
  [blockedView addSubview:blockedTitle];

  // Weekly chart section title
  NSTextField *weekTitle =
      [[NSTextField alloc] initWithFrame:NSMakeRect(30, 170, 200, 20)];
  weekTitle.bordered = NO;
  weekTitle.editable = NO;
  weekTitle.selectable = NO;
  weekTitle.drawsBackground = NO;
  weekTitle.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
  weekTitle.stringValue = @"This Week";
  [content addSubview:weekTitle];

  // Weekly chart
  self.weeklyChartView =
      [[NSView alloc] initWithFrame:NSMakeRect(30, 30, 440, 130)];
  self.weeklyChartView.wantsLayer = YES;
  [content addSubview:self.weeklyChartView];
}

- (NSView *)createStatViewWithFrame:(NSRect)frame {
  NSView *view = [[NSView alloc] initWithFrame:frame];
  view.wantsLayer = YES;
  view.layer.backgroundColor = [[NSColor controlBackgroundColor] CGColor];
  view.layer.cornerRadius = 8;
  return view;
}

- (void)configureStatLabel:(NSTextField *)label large:(BOOL)large {
  label.bordered = NO;
  label.editable = NO;
  label.selectable = NO;
  label.drawsBackground = NO;
  label.alignment = NSTextAlignmentCenter;

  if (large) {
    label.font = [NSFont systemFontOfSize:24 weight:NSFontWeightBold];
    label.textColor = [NSColor labelColor];
  } else {
    label.font = [NSFont systemFontOfSize:11];
    label.textColor = [NSColor secondaryLabelColor];
  }
}

- (void)refresh {
  DailyStats *today = [[FocusStats sharedStats] todayStats];
  CGFloat score = [[FocusStats sharedStats] calculateFocusScore];

  self.scoreLabel.stringValue = [NSString stringWithFormat:@"%.0f", score];
  self.pomodorosLabel.stringValue =
      [NSString stringWithFormat:@"%ld", (long)today.pomodorosCompleted];
  self.focusTimeLabel.stringValue =
      [NSString stringWithFormat:@"%ldm", (long)today.focusMinutes];
  self.blockedLabel.stringValue =
      [NSString stringWithFormat:@"%ld", (long)today.sitesBlocked];

  [self drawWeeklyChart];
}

- (void)drawWeeklyChart {
  // Remove old bars
  for (NSView *subview in [self.weeklyChartView.subviews copy]) {
    [subview removeFromSuperview];
  }

  NSArray *weekStats = [[FocusStats sharedStats] weeklyStats];
  NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
  dayFormatter.dateFormat = @"EEE";

  CGFloat barWidth = 40;
  CGFloat spacing = (440 - (barWidth * 7)) / 8;
  CGFloat maxHeight = 100;

  // Find max value for scaling
  NSInteger maxPomodoros = 1;
  for (DailyStats *stat in weekStats) {
    if (stat.pomodorosCompleted > maxPomodoros) {
      maxPomodoros = stat.pomodorosCompleted;
    }
  }

  for (NSInteger i = 0; i < weekStats.count; i++) {
    DailyStats *stat = weekStats[i];
    CGFloat x = spacing + i * (barWidth + spacing);

    // Bar
    CGFloat barHeight =
        maxHeight * ((CGFloat)stat.pomodorosCompleted / maxPomodoros);
    if (barHeight < 4 && stat.pomodorosCompleted > 0)
      barHeight = 4;

    NSView *bar =
        [[NSView alloc] initWithFrame:NSMakeRect(x, 20, barWidth, barHeight)];
    bar.wantsLayer = YES;
    bar.layer.cornerRadius = 4;
    bar.layer.backgroundColor =
        [[NSColor controlAccentColor] colorWithAlphaComponent:0.7].CGColor;
    [self.weeklyChartView addSubview:bar];

    // Day label
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.dateFormat = @"yyyy-MM-dd";
    NSDate *date = [parseFormatter dateFromString:stat.date];
    NSString *dayName = date ? [dayFormatter stringFromDate:date] : @"";

    NSTextField *dayLabel =
        [[NSTextField alloc] initWithFrame:NSMakeRect(x, 0, barWidth, 16)];
    dayLabel.bordered = NO;
    dayLabel.editable = NO;
    dayLabel.selectable = NO;
    dayLabel.drawsBackground = NO;
    dayLabel.font = [NSFont systemFontOfSize:10];
    dayLabel.textColor = [NSColor secondaryLabelColor];
    dayLabel.alignment = NSTextAlignmentCenter;
    dayLabel.stringValue = dayName;
    [self.weeklyChartView addSubview:dayLabel];
  }
}

@end
