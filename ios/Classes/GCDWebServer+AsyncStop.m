//  This category patches GCDWebServer to prevent UI freezes when stopping the server.
//
//  Problem:
//  GCDWebServer's -_stop method runs synchronously on whatever thread calls it.
//  When called from the main thread (e.g. during backgrounding), this can cause:
//  1. UI freezes while the server shuts down
//  2. Thread priority-inversion warnings because the server queue runs at a lower QoS
//
//  Solution:
//  We swizzle just the private -_stop method to ensure it always runs on the server's
//  own dispatch queue. This maintains the original logic but prevents blocking the
//  main thread.
//
//  Why this approach:
//  1. Minimal intervention - only affects the problematic method
//  2. Works for all callers of _stop, not just backgrounding
//  3. Uses GCDWebServer's own queue to maintain its threading model
//  4. Preserves all other behaviors and cleanup logic
//

#import "GCDWebServer+AsyncStop.h"
#import <objc/runtime.h>

@implementation GCDWebServer (AsyncStop)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Get the class and method we need to modify
        Class cls = [GCDWebServer class];
        SEL stopSEL = NSSelectorFromString(@"_stop");
        Method stopMthd = class_getInstanceMethod(cls, stopSEL);
        
        // Store the original implementation so we can call it later
        IMP originalIMP = method_getImplementation(stopMthd);
        
        // Create a new implementation that dispatches to the server's queue
        IMP newIMP = imp_implementationWithBlock(^(id self) {
            // Get GCDWebServer's private queue using runtime API
            // This queue is where the server normally does its work
            Ivar queueIvar = class_getInstanceVariable(cls, "_serverQueue");
            dispatch_queue_t serverQueue = object_getIvar(self, queueIvar);
            
            if (serverQueue) {
                // If we got the queue, dispatch the stop call to it
                // This prevents blocking the calling thread (usually main)
                dispatch_async(serverQueue, ^{
                    ((void (*)(id, SEL))originalIMP)(self, stopSEL);
                });
            } else {
                // Fallback: if we can't get the queue for some reason,
                // call the original implementation directly.
                // This preserves functionality even if internals change.
                ((void (*)(id, SEL))originalIMP)(self, stopSEL);
            }
        });
        
        // Replace the original _stop implementation with our async version
        method_setImplementation(stopMthd, newIMP);
    });
}

@end 