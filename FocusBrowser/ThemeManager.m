#import "ThemeManager.h"

NSNotificationName const ThemeDidChangeNotification =
    @"ThemeDidChangeNotification";

@implementation ThemeManager

+ (instancetype)sharedManager {
  static ThemeManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[ThemeManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _currentTheme = [[NSUserDefaults standardUserDefaults]
        integerForKey:@"FocusBrowser_Theme"];
    _accentColor = [NSColor colorWithRed:0.35
                                   green:0.55
                                    blue:1.0
                                   alpha:1.0]; // Modern blue

    [NSDistributedNotificationCenter.defaultCenter
        addObserver:self
           selector:@selector(systemThemeChanged:)
               name:@"AppleInterfaceThemeChangedNotification"
             object:nil];
  }
  return self;
}

- (void)systemThemeChanged:(NSNotification *)notification {
  if (self.currentTheme == AppThemeSystem) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ThemeDidChangeNotification
                      object:nil];
  }
}

- (void)setCurrentTheme:(AppTheme)currentTheme {
  _currentTheme = currentTheme;
  [[NSUserDefaults standardUserDefaults] setInteger:currentTheme
                                             forKey:@"FocusBrowser_Theme"];
  [self applyTheme];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ThemeDidChangeNotification
                    object:nil];
}

- (BOOL)isDarkMode {
  if (self.currentTheme == AppThemeLight)
    return NO;
  if (self.currentTheme == AppThemeDark)
    return YES;

  NSString *appearance = [[NSUserDefaults standardUserDefaults]
      stringForKey:@"AppleInterfaceStyle"];
  return [appearance isEqualToString:@"Dark"];
}

- (void)applyTheme {
  if (self.currentTheme == AppThemeLight) {
    [NSApp setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
  } else if (self.currentTheme == AppThemeDark) {
    [NSApp
        setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  } else {
    [NSApp setAppearance:nil];
  }
}

- (NSColor *)backgroundColor {
  if (self.isDarkMode) {
    return [NSColor colorWithSRGBRed:0.07 green:0.07 blue:0.07 alpha:1.0]; // Deepest Black
  } else {
    // Apple-style Off-White (F5F5F7)
    return [NSColor colorWithSRGBRed:0.96 green:0.96 blue:0.97 alpha:1.0];
  }
}

- (NSColor *)surfaceColor {
  if (self.isDarkMode) {
    return [NSColor colorWithSRGBRed:0.11 green:0.11 blue:0.12 alpha:1.0];
  } else {
    return [NSColor whiteColor]; // Pure White for surfaces on off-white bg
  }
}

- (NSColor *)elevatedSurfaceColor {
  if (self.isDarkMode) {
    return [NSColor colorWithSRGBRed:0.14 green:0.14 blue:0.15 alpha:1.0];
  } else {
    return [NSColor whiteColor];
  }
}

- (NSColor *)borderColor {
  if (self.isDarkMode) {
    return [NSColor colorWithWhite:1.0 alpha:0.08];
  } else {
    return [NSColor colorWithWhite:0.0 alpha:0.08];
  }
}

- (NSColor *)textPrimaryColor {
  if (self.isDarkMode) {
      return [NSColor colorWithSRGBRed:0.95 green:0.95 blue:0.96 alpha:1.0];
  } else {
      // Apple-style Primary Text (1D1D1F) - Soft Black
      return [NSColor colorWithSRGBRed:0.11 green:0.11 blue:0.12 alpha:1.0];
  }
}

- (NSColor *)textSecondaryColor {
  if (self.isDarkMode) {
      return [NSColor colorWithWhite:1.0 alpha:0.6];
  } else {
      return [NSColor colorWithWhite:0.0 alpha:0.6];
  }
}

- (NSColor *)textTertiaryColor {
  if (self.isDarkMode) {
      return [NSColor colorWithWhite:1.0 alpha:0.4];
  } else {
      return [NSColor colorWithWhite:0.0 alpha:0.4];
  }
}

@end
