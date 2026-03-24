#import "FocusTimerView.h"
#import "ThemeManager.h"
#import <QuartzCore/QuartzCore.h>

@interface FocusTimerView ()
@property(strong, nonatomic) CATextLayer *textLayer;
@property(strong, nonatomic) CAShapeLayer *backgroundLayer;
@property(strong, nonatomic) CAShapeLayer *progressLayer;
@end

@implementation FocusTimerView

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.wantsLayer = YES;
    _progress = 1.0;
    _strokeWidth = 3.5;
    _progressColor = [NSColor systemGreenColor];

    [self setupLayers];
  }
  return self;
}

- (void)setupLayers {
  // Background Circle
  self.backgroundLayer = [CAShapeLayer layer];
  self.backgroundLayer.fillColor = [NSColor clearColor].CGColor;
  self.backgroundLayer.strokeColor = [[ThemeManager sharedManager] borderColor].CGColor;
  self.backgroundLayer.lineWidth = self.strokeWidth;
  self.backgroundLayer.lineCap = kCALineCapRound;
  [self.layer addSublayer:self.backgroundLayer];

  // Progress Circle
  self.progressLayer = [CAShapeLayer layer];
  self.progressLayer.fillColor = [NSColor clearColor].CGColor;
  self.progressLayer.strokeColor = self.progressColor.CGColor;
  self.progressLayer.lineWidth = self.strokeWidth;
  self.progressLayer.lineCap = kCALineCapRound;
  self.progressLayer.strokeEnd = self.progress;

  // Rotate so it starts at top (12 o'clock) which is -90 degrees
  self.progressLayer.transform = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
  [self.layer addSublayer:self.progressLayer];

  // Text Layer
  self.textLayer = [CATextLayer layer];
  self.textLayer.alignmentMode = kCAAlignmentCenter;
  self.textLayer.fontSize = 13.0;
  self.textLayer.font = (__bridge CFTypeRef)[NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightSemibold];
  self.textLayer.foregroundColor = [[ThemeManager sharedManager] textPrimaryColor].CGColor;
  self.textLayer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
  [self.layer addSublayer:self.textLayer];
}

- (void)layout {
  [super layout];

  CGPoint center =
      CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
  CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) -
                    self.strokeWidth) /
                   2.0;

  NSBezierPath *circlePath = [NSBezierPath
      bezierPathWithOvalInRect:NSMakeRect(center.x - radius, center.y - radius,
                                          radius * 2, radius * 2)];
  CGPathRef path = [self cgPathFromBezierPath:circlePath];

  self.backgroundLayer.path = path;
  self.progressLayer.path = path;

  // Center progress layer rotation
  self.progressLayer.frame = self.bounds;
  self.backgroundLayer.frame = self.bounds;

  // Text positioning
  CGFloat fontHeight = 14.0;
  self.textLayer.frame = CGRectMake(0, center.y - (fontHeight / 2) + 1,
                                    self.bounds.size.width, fontHeight);
}

// Convert NSBezierPath to CGPath
- (CGPathRef)cgPathFromBezierPath:(NSBezierPath *)nsPath {
  CGMutablePathRef cgPath = CGPathCreateMutable();
  NSInteger n = [nsPath elementCount];

  for (NSInteger i = 0; i < n; i++) {
    NSPoint points[3];
    switch ([nsPath elementAtIndex:i associatedPoints:points]) {
    case NSMoveToBezierPathElement:
      CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
      break;
    case NSLineToBezierPathElement:
      CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
      break;
    case NSCurveToBezierPathElement:
      CGPathAddCurveToPoint(cgPath, NULL, points[0].x, points[0].y, points[1].x,
                            points[1].y, points[2].x, points[2].y);
      break;
    case NSClosePathBezierPathElement:
      CGPathCloseSubpath(cgPath);
      break;
    }
  }
  return cgPath;
}

- (void)setProgress:(CGFloat)progress {
  _progress = progress;
  self.progressLayer.strokeEnd = progress;
}

- (void)setProgressColor:(NSColor *)progressColor {
  _progressColor = progressColor;
  self.progressLayer.strokeColor = progressColor.CGColor;
}

- (void)setTimeString:(NSString *)timeString {
  _timeString = timeString;
  self.textLayer.string = timeString;
}

- (void)updateLayer {
  [super updateLayer];
  self.backgroundLayer.strokeColor = [[ThemeManager sharedManager] borderColor].CGColor;
  self.textLayer.foregroundColor = [[ThemeManager sharedManager] textPrimaryColor].CGColor;
}

- (void)startPulseAnimation {
  CABasicAnimation *pulse =
      [CABasicAnimation animationWithKeyPath:@"lineWidth"];
  pulse.fromValue = @(self.strokeWidth);
  pulse.toValue = @(self.strokeWidth + 2.0);
  pulse.duration = 1.0;
  pulse.autoreverses = YES;
  pulse.repeatCount = HUGE_VALF;
  [self.progressLayer addAnimation:pulse forKey:@"pulse"];
}

- (void)stopPulseAnimation {
  [self.progressLayer removeAnimationForKey:@"pulse"];
}

@end
