#ifndef SemenCheck_Bridging_Header_h
#define SemenCheck_Bridging_Header_h

#import <Foundation/Foundation.h>
#import "../Core/Exploit/worse_query.h"
#import "../Core/Exploit/pathleak.h"

NSString *AQCurrentAppGroup(void);
NSArray<NSDictionary<NSString *, NSString *> *> *AQInstalledApps(void);

#endif
