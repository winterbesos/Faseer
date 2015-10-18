//
//  FSLogManager+Peripheral.h
//  SLFarseer_iOS
//
//  Created by Go Salo on 15/3/18.
//  Copyright (c) 2015年 Eitdesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSBLELogProtocol.h"

@class FSBLELog;

@interface FSLogManager: NSObject

- (void)cleanLogBeforeDate:(NSDate *)date;
- (void)inputLog:(id<FSBLELogProtocol>)log;

- (NSArray *)logList;
- (void)uninstallLogFile;
- (BOOL)installLogFile;

@end
