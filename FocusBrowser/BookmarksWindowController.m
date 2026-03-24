#import "BookmarksWindowController.h"
#import "BookmarkManager.h"

@interface BookmarksWindowController () <NSTableViewDataSource, NSTableViewDelegate>

@property (strong, nonatomic) NSTableView *tableView;
@property (strong, nonatomic) NSArray<Bookmark *> *bookmarks;

@end

@implementation BookmarksWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 400)
                                                   styleMask:NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Bookmarks";
    window.minSize = NSMakeSize(400, 300);
    [window center];

    self = [super initWithWindow:window];
    if (self) {
        [self setupUI];
        [self reloadBookmarks];
    }
    return self;
}

- (void)setupUI {
    NSView *content = self.window.contentView;

    // Scroll view with table
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:content.bounds];
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSNoBorder;

    self.tableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 36;
    self.tableView.headerView = nil;
    self.tableView.doubleAction = @selector(openBookmark:);
    self.tableView.target = self;

    NSTableColumn *titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    titleColumn.title = @"Title";
    titleColumn.width = 200;
    [self.tableView addTableColumn:titleColumn];

    NSTableColumn *urlColumn = [[NSTableColumn alloc] initWithIdentifier:@"url"];
    urlColumn.title = @"URL";
    urlColumn.width = 280;
    [self.tableView addTableColumn:urlColumn];

    scrollView.documentView = self.tableView;
    [content addSubview:scrollView];
}

- (void)reloadBookmarks {
    self.bookmarks = [[BookmarkManager sharedManager] allBookmarks];
    [self.tableView reloadData];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.bookmarks.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (!cell) {
        cell = [[NSTextField alloc] init];
        cell.identifier = tableColumn.identifier;
        cell.bordered = NO;
        cell.editable = NO;
        cell.selectable = NO;
        cell.drawsBackground = NO;
        cell.lineBreakMode = NSLineBreakByTruncatingTail;
    }

    Bookmark *bookmark = self.bookmarks[row];
    if ([tableColumn.identifier isEqualToString:@"title"]) {
        cell.stringValue = bookmark.title ?: @"Untitled";
        cell.font = [NSFont systemFontOfSize:13];
    } else {
        cell.stringValue = bookmark.url ?: @"";
        cell.font = [NSFont systemFontOfSize:11];
        cell.textColor = [NSColor secondaryLabelColor];
    }

    return cell;
}

- (void)openBookmark:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row >= 0 && row < self.bookmarks.count) {
        Bookmark *bookmark = self.bookmarks[row];
        if (self.onBookmarkSelected) {
            self.onBookmarkSelected(bookmark.url);
        }
        [self.window close];
    }
}

- (void)keyDown:(NSEvent *)event {
    // Delete key to remove bookmark
    if (event.keyCode == 51) { // Backspace
        NSInteger row = self.tableView.selectedRow;
        if (row >= 0 && row < self.bookmarks.count) {
            Bookmark *bookmark = self.bookmarks[row];
            [[BookmarkManager sharedManager] removeBookmark:bookmark];
            [self reloadBookmarks];
        }
    } else {
        [super keyDown:event];
    }
}

@end
