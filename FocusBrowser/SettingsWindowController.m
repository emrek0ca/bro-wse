#import "SettingsWindowController.h"
#import "SettingsManager.h"
#import "ThemeManager.h"

@interface SettingsWindowController ()

@property (strong, nonatomic) NSTextField *homepageField;
@property (strong, nonatomic) NSPopUpButton *searchEnginePopup;
@property (strong, nonatomic) NSButton *restoreSessionCheckbox;

@end

@implementation SettingsWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 260)
                                                   styleMask:NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskFullSizeContentView
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Settings";
    window.titlebarAppearsTransparent = YES;
    window.titleVisibility = NSWindowTitleHidden;
    window.backgroundColor = [[ThemeManager sharedManager] backgroundColor];
    [window center];

    self = [super initWithWindow:window];
    if (self) {
        [self setupUI];
        [self loadCurrentSettings];
    }
    return self;
}

- (void)setupUI {
    NSView *content = self.window.contentView;
    content.wantsLayer = YES;

    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.alignment = NSLayoutAttributeLeading;
    mainStack.spacing = 20;
    mainStack.edgeInsets = NSEdgeInsetsMake(40, 30, 30, 30);
    [content addSubview:mainStack];

    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
    ]];

    // Title
    NSTextField *titleLabel = [NSTextField labelWithString:@"Settings"];
    titleLabel.font = [NSFont systemFontOfSize:18 weight:NSFontWeightBold];
    titleLabel.textColor = [[ThemeManager sharedManager] textPrimaryColor];
    [mainStack addArrangedSubview:titleLabel];

    [mainStack addArrangedSubview:[self createSeparator]];

    // Homepage Row
    NSStackView *homepageRow = [self createRowWithLabel:@"Homepage:"];
    self.homepageField = [[NSTextField alloc] init];
    self.homepageField.translatesAutoresizingMaskIntoConstraints = NO;
    self.homepageField.placeholderString = @"https://www.apple.com";
    self.homepageField.bezelStyle = NSTextFieldRoundedBezel;
    self.homepageField.focusRingType = NSFocusRingTypeNone;
    self.homepageField.target = self;
    self.homepageField.action = @selector(homepageChanged:);
    [homepageRow addArrangedSubview:self.homepageField];
    [mainStack addArrangedSubview:homepageRow];
    [self.homepageField.widthAnchor constraintEqualToConstant:250].active = YES;

    // Search Engine Row
    NSStackView *searchRow = [self createRowWithLabel:@"Search Engine:"];
    self.searchEnginePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.searchEnginePopup addItemsWithTitles:@[@"Google", @"DuckDuckGo", @"Bing"]];
    self.searchEnginePopup.target = self;
    self.searchEnginePopup.action = @selector(searchEngineChanged:);
    [searchRow addArrangedSubview:self.searchEnginePopup];
    [mainStack addArrangedSubview:searchRow];

    // Restore Session
    self.restoreSessionCheckbox = [NSButton checkboxWithTitle:@"Restore tabs on launch" target:self action:@selector(restoreSessionChanged:)];
    self.restoreSessionCheckbox.font = [NSFont systemFontOfSize:13];
    self.restoreSessionCheckbox.contentTintColor = [[ThemeManager sharedManager] textPrimaryColor];
    [mainStack addArrangedSubview:self.restoreSessionCheckbox];
}

- (NSStackView *)createRowWithLabel:(NSString *)text {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    row.spacing = 10;
    
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    label.textColor = [[ThemeManager sharedManager] textSecondaryColor];
    label.alignment = NSTextAlignmentRight;
    [label.widthAnchor constraintEqualToConstant:100].active = YES;
    
    [row addArrangedSubview:label];
    return row;
}

- (NSView *)createSeparator {
    NSView *sep = [[NSView alloc] init];
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    sep.wantsLayer = YES;
    sep.layer.backgroundColor = [[ThemeManager sharedManager] borderColor].CGColor;
    [sep.heightAnchor constraintEqualToConstant:1].active = YES;
    return sep;
}

- (void)loadCurrentSettings {
    SettingsManager *settings = [SettingsManager sharedManager];
    self.homepageField.stringValue = settings.homepage;
    [self.searchEnginePopup selectItemAtIndex:settings.searchEngine];
    self.restoreSessionCheckbox.state = settings.restoreSessionOnLaunch ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)homepageChanged:(id)sender {
    NSString *value = self.homepageField.stringValue;
    if (value.length > 0) {
        if (![value hasPrefix:@"http://"] && ![value hasPrefix:@"https://"] && ![value hasPrefix:@"focus://"]) {
            value = [@"https://" stringByAppendingString:value];
            self.homepageField.stringValue = value;
        }
        [SettingsManager sharedManager].homepage = value;
    }
}

- (void)searchEngineChanged:(id)sender {
    [SettingsManager sharedManager].searchEngine = self.searchEnginePopup.indexOfSelectedItem;
}

- (void)restoreSessionChanged:(id)sender {
    [SettingsManager sharedManager].restoreSessionOnLaunch = (self.restoreSessionCheckbox.state == NSControlStateValueOn);
}

@end
