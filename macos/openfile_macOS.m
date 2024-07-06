#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface PreviewHelper : NSObject <QLPreviewPanelDataSource, QLPreviewPanelDelegate>
@property (nonatomic, strong) NSArray<NSURL *> *fileURLs;
@end

@implementation PreviewHelper

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return self.fileURLs.count;
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return self.fileURLs[index];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:nil];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"Usage: %s [-f] <file_path1> <file_path2> ...", argv[0]);
            return 1;
        }

        BOOL fullscreen = NO;
        NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];

        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-f") == 0) {
                fullscreen = YES;
            } else {
                NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[i]]];
                [fileURLs addObject:url];
            }
        }

        if (fileURLs.count == 0) {
            NSLog(@"Usage: %s [-f] <file_path1> <file_path2> ...", argv[0]);
            return 1;
        }

        PreviewHelper *helper = [[PreviewHelper alloc] init];
        helper.fileURLs = fileURLs;

        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];

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

        [app run];
    }
    return 0;
}
#endif
