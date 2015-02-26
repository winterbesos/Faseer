//
//  FSInitBLEPacker.m
//  SLBTServiceDemo
//
//  Created by Go Salo on 2/15/15.
//  Copyright (c) 2015 Go Salo. All rights reserved.
//

#import "FSInitBLEPacker.h"
#import "FSPackerProtocol.h"
#import "FSPackageIn.h"
#import "FSCentralClient.h"

@interface FSInitBLEPacker () <FSPackerDelegate>

@end

@implementation FSInitBLEPacker

- (void)unpack:(FSPackageIn *)packageIn client:(id)client {
    Byte osType = [packageIn readByte];
    NSString *osVersion = [packageIn readString];
    NSString *deviceType = [packageIn readString];
    NSString *deviceName = [packageIn readString];
    NSString *bundleName = [packageIn readString];
    
    [client recvInitBLEWithOSType:osType osVersion:osVersion deviceType:deviceType deviceName:deviceName bundleName:bundleName];
}

@end