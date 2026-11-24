//
//  AppGroup.m
//  SemenCheck
//
//  Devuelve el App Group que la firma haya inyectado, leído de los propios
//  entitlements. Impactor y AltStore añaden el Team ID al identificador, así
//  que nunca se puede hardcodear.
//

#import <Foundation/Foundation.h>

typedef struct __SecTask *SecTaskRef;
extern SecTaskRef SecTaskCreateFromSelf(CFAllocatorRef allocator);
extern CFTypeRef SecTaskCopyValueForEntitlement(SecTaskRef task,
                                                CFStringRef entitlement,
                                                CFErrorRef *error);

NSString *AQCurrentAppGroup(void) {
    SecTaskRef task = SecTaskCreateFromSelf(NULL);
    if (!task) return nil;

    CFTypeRef value = SecTaskCopyValueForEntitlement(
        task, CFSTR("com.apple.security.application-groups"), NULL);
    CFRelease(task);
    if (!value) return nil;

    NSString *group = nil;
    if (CFGetTypeID(value) == CFArrayGetTypeID()) {
        CFArrayRef array = (CFArrayRef)value;
        if (CFArrayGetCount(array) > 0) {
            CFTypeRef first = CFArrayGetValueAtIndex(array, 0);
            if (first && CFGetTypeID(first) == CFStringGetTypeID()) {
                group = [NSString stringWithString:(__bridge NSString *)first];
            }
        }
    }
    CFRelease(value);
    return group;
}
