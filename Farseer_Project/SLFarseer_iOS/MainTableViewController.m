//
//  MainTableViewController.m
//  SLFarseer
//
//  Created by Go Salo on 15/4/4.
//  Copyright (c) 2015年 Qeekers. All rights reserved.
//

#import "MainTableViewController.h"
#import "FSBLECentralService.h"
#import <CoreBluetooth/CBPeripheral.h>
#import <objc/runtime.h>
#import <Farseer_Remote_iOS/Farseer_Remote_iOS.h>
#import "PeripheralTableViewCell.h"
#import "LogViewController.h"
#import "DocumentTableViewController.h"
#import "DirViewController.h"

static char AssociatedObjectHandle;

@interface MainTableViewController () <FSCentralClientDelegate>

@property (weak, nonatomic) IBOutlet UILabel *OSTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *OSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *displayLogTimeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *displayLogNumberSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *displayLogColorSwitch;

@end

@implementation MainTableViewController {
    __weak IBOutlet UIButton        *otherDeviceButton;
    __weak IBOutlet UILabel         *currentDeviceNameLabel;
    
    NSMutableArray                  *_peripheralsDataList;
    CBPeripheral                    *_activePeripheral;
    LogViewController               *_logViewController;
    DirViewController               *_remoteDirVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _logViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LogViewController"];
    _remoteDirVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DirViewController"];
    
    _peripheralsDataList = [NSMutableArray array];
    
    self.displayLogTimeSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:DISPLAY_LOG_TIME_KEY];
    self.displayLogNumberSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:DISPLAY_LOG_NUMBER_KEY];
    self.displayLogColorSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:DISPLAY_LOG_COLOR_KEY];
    
    [FSBLECentralService installWithDelegate:self stateChangedCallback:^(CBCentralManagerState state) {
        if (state == CBCentralManagerStatePoweredOn) {
            [self scanPeripheral];
            otherDeviceButton.hidden = YES;
        }
    }];
}

#pragma mark - Private Method

- (void)scanPeripheral {
    [FSBLECentralService setConnectPeripheralCallback:^(CBPeripheral *peripheral) {
        switch (peripheral.state) {
            case CBPeripheralStateConnected: {
                _activePeripheral = peripheral;
                currentDeviceNameLabel.text = peripheral.name;
                [self closePeripheralList];
            }
                break;
            default: {
                if (_activePeripheral.state != CBPeripheralStateConnected) {
                    otherDeviceButton.hidden = NO;
                    currentDeviceNameLabel.text = @"未连接";
                }
            }
                break;
        }
    }];
    [FSBLECentralService scanDidDisconvered:^(CBPeripheral *peripheral, NSNumber *RSSI) {
        NSInteger index = [_peripheralsDataList indexOfObject:peripheral];
        objc_setAssociatedObject(peripheral, &AssociatedObjectHandle, RSSI, OBJC_ASSOCIATION_RETAIN);
        
        if (index == NSNotFound) {
            if (peripheral != _activePeripheral) {
                [_peripheralsDataList addObject:peripheral];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_peripheralsDataList.count inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
            }
        } else {
            [_peripheralsDataList replaceObjectAtIndex:index withObject:peripheral];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
}

- (void)closePeripheralList {
    NSMutableArray *peripheralIndexPaths = [NSMutableArray array];
    for (int index = 1; index <= _peripheralsDataList.count; index ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [peripheralIndexPaths addObject:indexPath];
    }
    
    [self stopScanAndClearPeripheral];
    [self.tableView deleteRowsAtIndexPaths:peripheralIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    otherDeviceButton.hidden = NO;
}

- (void)stopScanAndClearPeripheral {
    [FSBLECentralService stopScan];
    [_peripheralsDataList removeAllObjects];
}

- (void)displayLogInfo:(FSBLELogInfo *)logInfo {
    NSString *osType = @"N/A";
    NSString *osVersion = @"N/A";
    NSString *deviceType = @"N/A";
    NSString *bundleName = @"N/A";
    if (logInfo) {
        switch (logInfo.log_type) {
            case BLEOSTypeIOS:
                osType = @"iOS";
                break;
            case BLEOSTypeOSX:
                osType = @"OSX";
                break;
        }
        osVersion = logInfo.log_OSVersion;
        deviceType = logInfo.log_deviceType;
        bundleName = logInfo.log_bundleName;
    }
    
    _OSTypeLabel.text = osType;
    _OSVersionLabel.text = osVersion;
    _deviceTypeLabel.text = deviceType;
    _appNameLabel.text = bundleName;
}

#pragma mark - BLE Client Delegate

- (void)client:(FSCentralClient *)client didReceiveLogInfo:(FSBLELogInfo *)logInfo; {
    [self displayLogInfo:logInfo];
}

- (void)client:(FSCentralClient *)client didReceiveLog:(FSBLELog *)log {
    [_logViewController insertLogWithLog:log];
}

/*
- (void)recvSendBoxInfo:(NSDictionary *)sendBoxInfo {
    [_remoteDirVC recvSandBoxInfo:sendBoxInfo];
}

- (void)recvSandBoxFile:(NSData *)sandBoxData {
    [_remoteDirVC recvSandBoxFile:sandBoxData];
}
 */

#pragma mark - Actions

- (IBAction)otherDeviceButtonAction:(id)sender {
    [self scanPeripheral];
}

- (IBAction)displayLogTimeSwitchAction:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:DISPLAY_LOG_TIME_KEY];
}

- (IBAction)displayLogNumberSwitchAction:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:DISPLAY_LOG_NUMBER_KEY];
}

- (IBAction)displayLogColorSwitchAction:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:DISPLAY_LOG_COLOR_KEY];
}

- (IBAction)logButtonAction:(id)sender {
    [self.navigationController pushViewController:_logViewController animated:YES];
}

#pragma mark - Table view data source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == 0) {
        return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if (section == 0) {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    } else {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 ) {
        return _peripheralsDataList.count + 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0 && row != 0) {
        static NSString *identifier = @"PeripheralCell";
        PeripheralTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"PeripheralTableViewCell" owner:self options:nil] firstObject];
        }
        
        CBPeripheral *peripheral = _peripheralsDataList[indexPath.row - 1];
        NSNumber *RSSI = objc_getAssociatedObject(peripheral, &AssociatedObjectHandle);
        [cell setPripheral:peripheral RSSI:RSSI];
        
        return cell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0 && row != 0) {
        CBPeripheral *peripheral = _peripheralsDataList[indexPath.row - 1];
        if (_activePeripheral != peripheral) {
            [FSBLECentralService disconnectPeripheral:_activePeripheral];
            [FSBLECentralService connectToPeripheral:peripheral];
        } else {
            [self closePeripheralList];
        }
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id targetViewController = [segue destinationViewController];
    if ([targetViewController isKindOfClass:[DocumentTableViewController class]]) {
        [_remoteDirVC setRemotePath:@""];
        [targetViewController setRemoteDirVC:(DirViewController *)_remoteDirVC];
    }
}


@end