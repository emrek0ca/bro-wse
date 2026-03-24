#import <Foundation/Foundation.h>

@interface Bookmark : NSObject <NSCoding, NSSecureCoding>

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *url;
@property (strong, nonatomic) NSDate *dateAdded;

+ (instancetype)bookmarkWithTitle:(NSString *)title url:(NSString *)url;

@end

@interface BookmarkManager : NSObject

+ (instancetype)sharedManager;

- (NSArray<Bookmark *> *)allBookmarks;
- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url;
- (void)removeBookmark:(Bookmark *)bookmark;
- (BOOL)isBookmarked:(NSString *)url;

@end
