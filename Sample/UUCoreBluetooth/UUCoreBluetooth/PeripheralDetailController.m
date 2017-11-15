//
//  PeripheralDetailController.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/19/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "PeripheralDetailController.h"
#import "PeripheralDetailCell.h"
#import "ServiceDetailCell.h"
#import "ServiceDetailController.h"
#import "UUCoreBluetooth.h"
#import "UUMacros.h"

@interface PeripheralDetailController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *connectToolbarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *readRssiToolbarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *discoverServicesToolbarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pollRssiToolbarButton;

@end

@implementation PeripheralDetailController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.peripheral.name;
    
    [self refreshToolbar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([@"showServiceDetail" isEqualToString:segue.identifier])
    {
        ServiceDetailController* c = [segue destinationViewController];
        c.peripheral = self.peripheral;
        c.service = sender;
    }
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 1;
    
    count += 1;
    //count += self.peripheral.peripheral.services.count;
    
    return count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else if (section == 1)
    {
        return self.peripheral.peripheral.services.count;
    }
    else
    {
        return 0;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Info";
    }
    else if (section == 1)
    {
        return @"Services";
    }
    else
    {
        return @"";
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        PeripheralDetailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PeripheralDetailCell" forIndexPath:indexPath];
        [cell update:self.peripheral];
        return cell;
    }
    else if (indexPath.section == 1)
    {
        ServiceDetailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceDetailCell" forIndexPath:indexPath];
        
        CBService* service = self.peripheral.peripheral.services[indexPath.row];
        [cell update:service];
        
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        CBService* service = self.peripheral.peripheral.services[indexPath.row];
        [self performSegueWithIdentifier:@"showServiceDetail" sender:service];
    }
}

- (void) refreshTable
{
    UUDispatchMain(^
    {
        [self.tableView reloadData];
    });
}

- (void) refreshToolbar
{
    if ([NSThread isMainThread])
    {
        [self doRefreshToolbar];
    }
    else
    {
        UUDispatchMain(^
        {
            [self doRefreshToolbar];
        });
    }
}

- (void) doRefreshToolbar
{
    switch (self.peripheral.peripheralState)
    {
        case CBPeripheralStateConnected:
        {
            self.connectToolbarButton.title = @"Disconnect";
            self.connectToolbarButton.enabled = YES;
            self.readRssiToolbarButton.enabled = YES;
            self.pollRssiToolbarButton.enabled = YES;
            self.discoverServicesToolbarButton.enabled = YES;
            break;
        }
            
        case CBPeripheralStateConnecting:
        {
            self.connectToolbarButton.title = @"Disconnect";
            self.connectToolbarButton.enabled = NO;
            self.readRssiToolbarButton.enabled = NO;
            self.pollRssiToolbarButton.enabled = NO;
            self.discoverServicesToolbarButton.enabled = NO;
            break;
        }
            
        case CBPeripheralStateDisconnecting:
        {
            self.connectToolbarButton.title = @"Connect";
            self.connectToolbarButton.enabled = NO;
            self.readRssiToolbarButton.enabled = NO;
            self.pollRssiToolbarButton.enabled = NO;
            self.discoverServicesToolbarButton.enabled = NO;
            break;
        }
            
        case CBPeripheralStateDisconnected:
        {
            self.connectToolbarButton.title = @"Connect";
            self.connectToolbarButton.enabled = YES;
            self.readRssiToolbarButton.enabled = NO;
            self.pollRssiToolbarButton.enabled = NO;
            self.discoverServicesToolbarButton.enabled = NO;
            break;
        }
    }
    
    if ([[UUCoreBluetooth sharedInstance] isPollingForRssi:self.peripheral])
    {
        self.pollRssiToolbarButton.title = @"Stop Polling";
    }
    else
    {
        self.pollRssiToolbarButton.title = @"Poll RSSI";
    }
}

- (IBAction)onConnect:(id)sender
{
    if (self.peripheral.peripheralState == CBPeripheralStateDisconnected)
    {
        [[UUCoreBluetooth sharedInstance] connectPeripheral:self.peripheral
                                                    timeout:30.0f
                                          disconnectTimeout:10.0f
                                                  connected:^(UUPeripheral * _Nonnull peripheral)
        {
            self.peripheral = peripheral;
            [self refreshTable];
            [self refreshToolbar];
        }
        disconnected:^(UUPeripheral * _Nonnull peripheral, NSError * _Nullable error)
        {
            self.peripheral = peripheral;
            [self refreshTable];
            [self refreshToolbar];
        }];
        
        // Should pick up the 'connecting' state of CBPeripheral
        [self refreshTable];
        [self refreshToolbar];
    }
    else
    {
        [[UUCoreBluetooth sharedInstance] disconnectPeripheral:self.peripheral timeout:10.0f];
    }
}

- (IBAction)onReadRssi:(id)sender
{
    [self.peripheral.peripheral uuReadRssi:30.0f completion:^(CBPeripheral * _Nonnull peripheral, NSNumber * _Nonnull rssi, NSError * _Nullable error)
    {
        //self.peripheral = peripheral;
        [self refreshTable];
        [self refreshToolbar];
    }];
}

- (IBAction)onPollRssi:(id)sender
{
    if ([[UUCoreBluetooth sharedInstance] isPollingForRssi:self.peripheral])
    {
        [[UUCoreBluetooth sharedInstance] stopRssiPolling:self.peripheral];
        [self refreshTable];
        [self refreshToolbar];
    }
    else
    {
        [[UUCoreBluetooth sharedInstance] startRssiPolling:self.peripheral
                                                  interval:1.0f
                                   peripheralUpdated:^(UUPeripheral * _Nonnull peripheral)
        {
            NSLog(@"Got RSSI update: %@", peripheral.rssi);
            
            self.peripheral = peripheral;
            [self refreshTable];
            [self refreshToolbar];
        }];
    }
}

- (IBAction)onDiscoverServices:(id)sender
{
    [self.peripheral.peripheral uuDiscoverServices:nil
                                timeout:30.0f
                             completion:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error)
    {
        //self.peripheral = peripheral;
        [self refreshTable];
        [self refreshToolbar];
    }];
}


@end
