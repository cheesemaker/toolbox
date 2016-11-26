//
//  PeripheralListController.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/19/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "PeripheralListController.h"
#import "UUCoreBluetooth.h"
#import "PeripheralListTableCell.h"
#import "ServiceListController.h"
#import "PeripheralDetailController.h"
#import "UUTimer.h"
#import "UUDictionary.h"

@interface PeripheralListController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *startScanButton;
@property (strong, nonatomic) IBOutlet UIButton *stopScanButton;

@property (strong, nonatomic) NSArray<PeripheralListTableRow*>* tableData;
@property (strong, nonatomic) NSMutableDictionary<NSString*, PeripheralListTableRow*>* deviceList;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *startStopScanningButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@end

@implementation PeripheralListController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.deviceList = [NSMutableDictionary dictionary];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.title = @"UUCoreBluetooth";
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopScanning];
}

- (void) handlePeripheralFound:(UUPeripheral*)peripheral tryConnect:(BOOL)tryConnect
{
    PeripheralListTableRow* row =  [self.deviceList uuSafeGet:peripheral.identifier forClass:[PeripheralListTableRow class]];
    if (!row)
    {
        row = [[PeripheralListTableRow alloc] init];
    }
    
    row.peripheral = peripheral;
    
    [self.deviceList setValue:row forKey:peripheral.identifier];
    
    self.tableData = [self.deviceList.allValues sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"peripheral.rssi" ascending:NO] ]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeripheralListTableRow* cellData = self.tableData[indexPath.row];
    
    PeripheralListTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PeripheralListTableCell" forIndexPath:indexPath];
    [cell update:cellData];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeripheralListTableRow* cellData = self.tableData[indexPath.row];
    //cellData.isExpanded = !cellData.isExpanded;
    //[self.deviceList setValue:cellData forKey:cellData.peripheral.identifier];
    
    [self performSegueWithIdentifier:@"showPeripheralDetail" sender:cellData.peripheral];
    
}

- (IBAction)onStartStopScan:(id)sender
{
    if ([[UUCoreBluetooth sharedInstance] isScanning])
    {
        [self stopScanning];
    }
    else
    {
        [self startScanning];
    }
}

- (IBAction)onSettings:(id)sender
{
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"showPeripheralDetail" isEqualToString:segue.identifier])
    {
        PeripheralDetailController* c = [segue destinationViewController];
        c.peripheral = sender;
    }
}

- (void) startScanning
{
    NSMutableArray* filters = [NSMutableArray array];
    [filters addObject:[UURssiPeripheralFilter filterWithRssi:@(-100)]];
    
    [[UUCoreBluetooth sharedInstance] startScanForServices:nil
                                           allowDuplicates:NO
                                           peripheralClass:nil
                                                   filters:filters
                                   peripheralFoundCallback:^(UUPeripheral * _Nonnull peripheral)
     {
         NSLog(@"Found UU Peripheral: %@, rssi: %@, advertisement: %@, connectable: %@, state: %@, lastBeaconTime: %@",
               peripheral.name, peripheral.rssi, peripheral.advertisementData, @(peripheral.isConnectable), UUCBPeripheralStateToString(peripheral.peripheralState),
               peripheral.lastAdvertisementTime);
         
         [self handlePeripheralFound:peripheral tryConnect:NO];
     }];
    
    [self updateScanButtonText];
    
    UUTimer* t = [UUTimer findActiveTimer:@"UIRefreshTimer"];
    [t cancel];
    
    t = [[UUTimer alloc] initWithId:@"UIRefreshTimer"
                       interval:1.0f
                       userInfo:nil
                         repeat:YES
                          queue:[UUTimer mainThreadTimerQueue]
                          block:^(UUTimer * _Nonnull timer)
    {
        [self.tableView reloadData];
    }];
    
    [t start];
}

- (void) stopScanning
{
    UUTimer* t = [UUTimer findActiveTimer:@"UIRefreshTimer"];
    [t cancel];
    
    [[UUCoreBluetooth sharedInstance] stopScanning];
    [self updateScanButtonText];
}

- (void) updateScanButtonText
{
    if ([[UUCoreBluetooth sharedInstance] isScanning])
    {
        self.startStopScanningButton.title = @"Stop";
    }
    else
    {
        self.startStopScanningButton.title = @"Scan";
    }
}

@end
