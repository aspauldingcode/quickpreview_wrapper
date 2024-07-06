use cocoa::appkit::{NSApp, NSApplication};
use cocoa::base::{id, nil, YES};
use cocoa::foundation::{NSAutoreleasePool, NSString};
use objc::{class, msg_send, sel, sel_impl};

pub fn open_quicklook(filename: &str, fullscreen: bool) {
    unsafe {
        let pool = NSAutoreleasePool::new(nil);

        let app = NSApp();
        app.setActivationPolicy_(cocoa::appkit::NSApplicationActivationPolicyRegular);

        let url = NSString::alloc(nil).init_str(filename);
        let workspace: id = msg_send![class!(NSWorkspace), sharedWorkspace];
        let _: () = msg_send![workspace, openFile:url];

        if fullscreen {
            let _: () = msg_send![app, toggleFullScreen:nil];
        }

        app.run();
        pool.drain();
    }
}
