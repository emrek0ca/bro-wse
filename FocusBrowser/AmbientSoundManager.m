#import "AmbientSoundManager.h"

// Note: This uses system sounds as placeholders
// In a real app, you would bundle actual ambient sound files

@interface AmbientSoundManager ()

@property (assign, nonatomic, readwrite) AmbientSound currentSound;
@property (assign, nonatomic, readwrite) BOOL isPlaying;
@property (strong, nonatomic) NSTimer *loopTimer;

@end

@implementation AmbientSoundManager

+ (instancetype)sharedManager {
    static AmbientSoundManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AmbientSoundManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _volume = 0.5;
        _currentSound = AmbientSoundNone;
        _isPlaying = NO;
    }
    return self;
}

- (void)playSound:(AmbientSound)sound {
    [self stop];

    if (sound == AmbientSoundNone) return;

    self.currentSound = sound;
    self.isPlaying = YES;

    // Placeholder: In production, load and play actual audio files
    // For now, we just track the state
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AmbientSoundStateChanged" object:nil];
}

- (void)stop {
    self.isPlaying = NO;
    self.currentSound = AmbientSoundNone;
    [self.loopTimer invalidate];
    self.loopTimer = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"AmbientSoundStateChanged" object:nil];
}

- (void)toggle {
    if (self.isPlaying) {
        [self stop];
    } else if (self.currentSound != AmbientSoundNone) {
        [self playSound:self.currentSound];
    } else {
        [self playSound:AmbientSoundRain]; // Default to rain
    }
}

- (NSString *)soundName:(AmbientSound)sound {
    switch (sound) {
        case AmbientSoundNone: return @"None";
        case AmbientSoundRain: return @"Rain";
        case AmbientSoundForest: return @"Forest";
        case AmbientSoundOcean: return @"Ocean Waves";
        case AmbientSoundCafe: return @"Coffee Shop";
        case AmbientSoundWhiteNoise: return @"White Noise";
    }
}

- (NSArray<NSNumber *> *)availableSounds {
    return @[
        @(AmbientSoundNone),
        @(AmbientSoundRain),
        @(AmbientSoundForest),
        @(AmbientSoundOcean),
        @(AmbientSoundCafe),
        @(AmbientSoundWhiteNoise)
    ];
}

@end
