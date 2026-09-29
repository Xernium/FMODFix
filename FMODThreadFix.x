// FMODFix: generic fix for older FMOD on iOS 10 (32-bit).
// Originally intended as a simple fix in B4BioBoss, I found out that this fix applies to a lot more apps.
// Fixes : Dead Space, Mass Effect Infiltrator and probably many others
//
//    This took a while to figure out: FMOD EX 4.44 has a (for this version) wrong thread stack size (8KB). 
//    That fails on modern (maybe 10+, idk) iOS because pthread_attr_setstacksize throws you a brick (EINVAL) if you do
//    dare request something that small (yea page alignment is at 16KB but anyway)
//    Effect is that the stream is never created but does create a ton of other errors that obscure the origin (FMOD_ERR_INTERNAL among others)
//    Fix is simple, force it to use 16KB where it fails. Very dumb. Should also work / not create a conflict on iOS 7/8 but I don't know honestly.
//    
//    This tweak is now generic, it should load into every UIKit app and it should hopefully find the target correctly.
//    That is unless someone stripped the thread name for it though ...
// 

#include <substrate.h>
#include <pthread.h>
#include <limits.h>
#include <errno.h>
#include <unistd.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <string.h>
#include <Foundation/Foundation.h>

#define LOG(fmt, ...) NSLog(@"[FMODFix] " fmt, ##__VA_ARGS__)

static const void *gMainHeader = NULL;

static int (*orig_setstacksize)(pthread_attr_t *, size_t);
static int fixed_setstacksize(pthread_attr_t *attr, size_t size) {
    int r = orig_setstacksize(attr, size);
    if (r != EINVAL || !gMainHeader) return r;
    void *caller = __builtin_return_address(0);
    
    Dl_info info;
    // only the game's own calls
    if (!dladdr(caller, &info) || info.dli_fbase != gMainHeader) return r; 
    
    size_t page = (size_t)getpagesize();
    size_t want = size < PTHREAD_STACK_MIN ? PTHREAD_STACK_MIN : size;
    if (want < 16384) want = 16384;
    want = (want + page - 1) & ~(page - 1);
    int r2 = orig_setstacksize(attr, want);
    LOG(@"setstacksize(%zu) = EINVAL from header+0x%lx -> retried with %zu = %d",
        size, (unsigned long)((uintptr_t)caller - (uintptr_t)gMainHeader), want, r2);
    return r2;
}

static const char kFMODMarker[] = "FMOD file thread";

static BOOL mainExecutableUsesFMODEx(const struct mach_header *mh) {
    unsigned long size = 0;
    const char *cstr = (const char *)getsectiondata(mh, "__TEXT", "__cstring", &size);
    
    return cstr && size && memmem(cstr, size, kFMODMarker, sizeof(kFMODMarker)) != NULL; 
}

%ctor {
    const char *path = _dyld_get_image_name(0);
    // User apps only
    if (!path || strncmp(path, "/var/containers/Bundle/Application/", 35) != 0) return; 
    const struct mach_header *mh = _dyld_get_image_header(0);
    if (!mainExecutableUsesFMODEx(mh)) return;
    gMainHeader = mh;
    MSHookFunction((void *)pthread_attr_setstacksize, (void *)fixed_setstacksize, (void **)&orig_setstacksize);
    LOG(@"FMOD Ex found in %s, hooked (main header %p)", getprogname(), gMainHeader);
}
