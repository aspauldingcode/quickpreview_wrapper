#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface PreviewHelper : NSObject <QLPreviewPanelDataSource, QLPreviewPanelDelegate>
@property (nonatomic, strong) NSArray<NSURL *> *fileURLs;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSTimer *visibilityTimer;
@end

@implementation PreviewHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentIndex = 0;
    }
    return self;
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return self.fileURLs.count;
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return self.fileURLs[index];
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    if ([event type] == NSEventTypeKeyDown) {
        switch ([event keyCode]) {
            case 123: // Left arrow
                self.currentIndex = (self.currentIndex - 1 + self.fileURLs.count) % self.fileURLs.count;
                [panel reloadData];
                return YES;
            case 124: // Right arrow
                self.currentIndex = (self.currentIndex + 1) % self.fileURLs.count;
                [panel reloadData];
                return YES;
            case 53: // Esc key
                [panel close];
                return YES;
        }
    }
    return NO;
}

- (NSInteger)previewPanel:(QLPreviewPanel *)panel currentPreviewItemIndex:(NSInteger)index {
    return self.currentIndex;
}

- (void)previewPanelDidClose:(QLPreviewPanel *)panel {
    [NSApp terminate:nil];
}

- (void)startVisibilityCheck {
    self.visibilityTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkVisibility) userInfo:nil repeats:YES];
}

- (void)checkVisibility {
    if (![QLPreviewPanel sharedPreviewPanelExists] || ![[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [self.visibilityTimer invalidate];
        [NSApp terminate:nil];
    }
}

@end

int openFiles(int argc, const char **argv, int fullscreen) {
    @autoreleasepool {
        NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];
        for (int i = 0; i < argc; i++) {
            NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[i]]];
            [fileURLs addObject:url];
        }

        if (fileURLs.count == 0) {
            NSLog(@"No files to open");
            return 1;
        }

        PreviewHelper *helper = [[PreviewHelper alloc] init];
        helper.fileURLs = fileURLs;

        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];

        QLPreviewPanel *previewPanel = [QLPreviewPanel sharedPreviewPanel];
        [previewPanel setDataSource:helper];
        [previewPanel setDelegate:helper];
        [previewPanel makeKeyAndOrderFront:nil];
        [previewPanel reloadData];

        if (fullscreen) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [previewPanel enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
            });
        }

        [helper startVisibilityCheck];

        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
#endif
