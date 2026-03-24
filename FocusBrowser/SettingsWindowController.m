#import "SettingsWindowController.h"
#import "SettingsManager.h"

@interface SettingsWindowController ()

@property (strong, nonatomic) NSTextField *homepageField;
@property (strong, nonatomic) NSPopUpButton *searchEnginePopup;
@property (strong, nonatomic) NSButton *restoreSessionCheckbox;

@end

@implementation SettingsWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 450, 200)
                                                   styleMask:NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Settings";
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

    CGFloat y = 150;
    CGFloat labelWidth = 120;
    CGFloat fieldX = 140;

    // Homepage
    NSTextField *homepageLabel = [self createLabel:@"Homepage:"];
    homepageLabel.frame = NSMakeRect(20, y, labelWidth, 22);
    [content addSubview:homepageLabel];

    self.homepageField = [[NSTextField alloc] initWithFrame:NSMakeRect(fieldX, y, 280, 24)];
    self.homepageField.placeholderString = @"https://www.apple.com";
    self.homepageField.bezelStyle = NSTextFieldRoundedBezel;
    self.homepageField.target = self;
    self.homepageField.action = @selector(homepageChanged:);
    [content addSubview:self.homepageField];

    y -= 40;

    // Search Engine
    NSTextField *searchLabel = [self createLabel:@"Search Engine:"];
    searchLabel.frame = NSMakeRect(20, y, labelWidth, 22);
    [content addSubview:searchLabel];

    self.searchEnginePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(fieldX, y, 150, 26) pullsDown:NO];
    [self.searchEnginePopup addItemsWithTitles:@[@"Google", @"DuckDuckGo", @"Bing"]];
    self.searchEnginePopup.target = self;
    self.searchEnginePopup.action = @selector(searchEngineChanged:);
    [content addSubview:self.searchEnginePopup];

    y -= 40;

    // Restore Session
    self.restoreSessionCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(fieldX, y, 250, 22)];
    self.restoreSessionCheckbox.title = @"Restore tabs on launch";
    [self.restoreSessionCheckbox setButtonType:NSButtonTypeSwitch];
    self.restoreSessionCheckbox.target = self;
    self.restoreSessionCheckbox.action = @selector(restoreSessionChanged:);
    [content addSubview:self.restoreSessionCheckbox];
}

- (NSTextField *)createLabel:(NSString *)text {
    NSTextField *label = [[NSTextField alloc] init];
    label.stringValue = text;
    label.bordered = NO;
    label.editable = NO;
    label.selectable = NO;
    label.drawsBackground = NO;
    label.font = [NSFont systemFontOfSize:13];
    label.alignment = NSTextAlignmentRight;
    return label;
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
        if (![value hasPrefix:@"http://"] && ![value hasPrefix:@"https://"]) {
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
