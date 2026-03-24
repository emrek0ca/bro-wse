#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, AppTheme) {
    AppThemeSystem = 0,
    AppThemeLight,
    AppThemeDark
};

@interface ThemeManager : NSObject

@property (assign, nonatomic) AppTheme currentTheme;
@property (assign, nonatomic, readonly) BOOL isDarkMode;
@property (strong, nonatomic) NSColor *accentColor;

// Colors
@property (strong, nonatomic, readonly) NSColor *backgroundColor;
@property (strong, nonatomic, readonly) NSColor *surfaceColor;
@property (strong, nonatomic, readonly) NSColor *elevatedSurfaceColor;
@property (strong, nonatomic, readonly) NSColor *borderColor;
@property (strong, nonatomic, readonly) NSColor *textPrimaryColor;
@property (strong, nonatomic, readonly) NSColor *textSecondaryColor;
@property (strong, nonatomic, readonly) NSColor *textTertiaryColor;

+ (instancetype)sharedManager;
- (void)applyTheme;

@end

extern NSNotificationName const ThemeDidChangeNotification;
