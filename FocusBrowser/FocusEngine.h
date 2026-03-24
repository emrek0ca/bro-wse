#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Bildirim Adları
extern NSNotificationName const FocusStateDidChangeNotification;
extern NSNotificationName const FocusTimerDidTickNotification;

// Odak Durumları (State)
typedef NS_ENUM(NSInteger, FocusState) {
  FocusStateIdle,
  FocusStateFlow,
  FocusStateBreak
};

@interface FocusEngine : NSObject

// --- Durum Sorguları (Salt Okunur) ---
// Sadece FocusEngine değiştirebilir. UI sadece okur.

@property(nonatomic, readonly) FocusState state;
@property(nonatomic, readonly) NSTimeInterval timeRemaining;
@property(nonatomic, readonly) NSTimeInterval totalDuration;
@property(nonatomic, readonly) CGFloat progress;     // 0.0 - 1.0
@property(nonatomic, readonly) BOOL isZenModeActive; // Flow durumunda YES
@property(nonatomic, readonly) BOOL isStrict;        // Strict mode active?

// Singleton Erişimi
+ (instancetype)sharedEngine;

// --- Intent (Niyet) Metodları ---
// Durum değişiklikleri için TEK giriş noktalarıdır.

// Kullanıcı Akış Başlatmak İstiyor (StartFlow)
// Precondition: State == Idle
- (void)startFlowSession:(NSInteger)minutes strict:(BOOL)strict;

// Kullanıcı Vazgeçmek İstiyor (AbandonFlow)
// Precondition: State == Flow
- (void)abandonSession;

// Kullanıcı Molayı Atlamak İstiyor (SkipBreak)
// Precondition: State == Break
- (void)skipBreak;

// Oturum/Mola Bittiğinde (Normalde Timer çağırır, ama manuel test için açık
// olabilir)
- (void)endSession;

@end

NS_ASSUME_NONNULL_END
