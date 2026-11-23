//
//  InstalledApps.m
//  Atalaya
//
//  Lista de apps instaladas. Se usa la API privada LSApplicationWorkspace,
//  aceptada en App Store y TestFlight. Si falla, la app cae a los esquemas
//  declarados en Info.plist.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;
@end

NSArray<NSDictionary<NSString *, NSString *> *> *AQInstalledApps(void) {
    NSMutableArray *out = [NSMutableArray array];
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass) {
        id workspace = [workspaceClass performSelector:@selector(defaultWorkspace)];
        if ([workspace respondsToSelector:@selector(allInstalledApplications)]) {
            NSArray *apps = [workspace performSelector:@selector(allInstalledApplications)];
            for (id app in apps) {
                NSString *bundleID = [app valueForKey:@"bundleIdentifier"];
                NSString *name = [app valueForKey:@"localizedName"];
                if (bundleID.length == 0) continue;
                [out addObject:@{ @"bundleID": bundleID,
                                  @"name": name.length ? name : bundleID }];
            }
        }
    }
    return out;
}
