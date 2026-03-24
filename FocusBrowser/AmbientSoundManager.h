#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, AmbientSound) {
    AmbientSoundNone = 0,
    AmbientSoundRain,
    AmbientSoundForest,
    AmbientSoundOcean,
    AmbientSoundCafe,
    AmbientSoundWhiteNoise
};

@interface AmbientSoundManager : NSObject

@property (assign, nonatomic, readonly) AmbientSound currentSound;
@property (assign, nonatomic) CGFloat volume;
@property (assign, nonatomic, readonly) BOOL isPlaying;

+ (instancetype)sharedManager;

- (void)playSound:(AmbientSound)sound;
- (void)stop;
- (void)toggle;
- (NSString *)soundName:(AmbientSound)sound;
- (NSArray<NSNumber *> *)availableSounds;

@end
