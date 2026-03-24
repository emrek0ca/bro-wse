#import "BookmarkManager.h"

static NSString * const kBookmarksKey = @"FocusBrowser_Bookmarks";

@implementation Bookmark

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)bookmarkWithTitle:(NSString *)title url:(NSString *)url {
    Bookmark *bookmark = [[Bookmark alloc] init];
    bookmark.title = title;
    bookmark.url = url;
    bookmark.dateAdded = [NSDate date];
    return bookmark;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _url = [coder decodeObjectOfClass:[NSString class] forKey:@"url"];
        _dateAdded = [coder decodeObjectOfClass:[NSDate class] forKey:@"dateAdded"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.dateAdded forKey:@"dateAdded"];
}

@end

@interface BookmarkManager ()

@property (strong, nonatomic) NSMutableArray<Bookmark *> *bookmarks;

@end

@implementation BookmarkManager

+ (instancetype)sharedManager {
    static BookmarkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BookmarkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadBookmarks];
    }
    return self;
}

- (void)loadBookmarks {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kBookmarksKey];
    if (data) {
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class], [Bookmark class], nil];
        NSError *error = nil;
        NSMutableArray *loaded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        if (loaded) {
            self.bookmarks = loaded;
        } else {
            self.bookmarks = [NSMutableArray array];
        }
    } else {
        self.bookmarks = [NSMutableArray array];
    }
}

- (void)saveBookmarks {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.bookmarks requiringSecureCoding:YES error:&error];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kBookmarksKey];
    }
}

- (NSArray<Bookmark *> *)allBookmarks {
    return [self.bookmarks copy];
}

- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url {
    if ([self isBookmarked:url]) return;

    Bookmark *bookmark = [Bookmark bookmarkWithTitle:title url:url];
    [self.bookmarks insertObject:bookmark atIndex:0];
    [self saveBookmarks];
}

- (void)removeBookmark:(Bookmark *)bookmark {
    [self.bookmarks removeObject:bookmark];
    [self saveBookmarks];
}

- (BOOL)isBookmarked:(NSString *)url {
    for (Bookmark *bookmark in self.bookmarks) {
        if ([bookmark.url isEqualToString:url]) {
            return YES;
        }
    }
    return NO;
}

@end
