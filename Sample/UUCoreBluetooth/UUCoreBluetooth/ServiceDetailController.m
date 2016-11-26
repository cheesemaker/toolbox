//
//  ServiceDetailController.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/18/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "ServiceDetailController.h"
#import "ServiceDetailCell.h"
#import "CharacteristicTableCell.h"
#import "UUMacros.h"
#import "UUData.h"

@interface ServiceDetailController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *discoverCharacteristicsToolbarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *discoverIncludedServicesToolbarButton;


@end

@implementation ServiceDetailController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.peripheral.name;
    
    //[self updatePeripheralState];
    
//    if (self.peripheral.state != CBPeripheralStateConnected)
//    {
        /*
        [[UUCoreBluetooth sharedInstance] connectPeripheral:self.peripheral
                                                    timeout:30.0f
                                                  connected:^(UUPeripheral * _Nonnull peripheral)
         {
             [self updatePeripheralState];
             [self scanForCharacteristics];
         }
         disconnected:^(UUPeripheral * _Nonnull peripheral, NSError * _Nullable error)
         {
             [self updatePeripheralState];
             
         }];*/
    /*}
    else
    {
        //[self scanForCharacteristics];
    }*/
}

/*
- (void) scanForCharacteristics
{
    [self.peripheral uuDiscoverCharacteristics:nil
                                    forService:self.service
                                       timeout:30.0f
                                    completion:^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSError * _Nullable error)
     {
         UUDispatchMain(^
         {
             self.tableData = service.characteristics;
             [self.tableView reloadData];
         });
     }];
}*/

/*
- (void) updatePeripheralState
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       //self.navigationItem.prompt = UUCBPeripheralStateToString(self.peripheral.peripheralState);
                   });
}*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3; // Service Detail, Characteristic List, Included Services List
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
            
        case 1:
            return self.service.characteristics.count;
            
        case 2:
            return self.service.includedServices.count;
            
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            return @"Info";
        }
            
        case 1:
        {
            return @"Characteristics";
        }
            
        case 2:
        {
            return @"Included Services";
        }
            
        default:
        {
            return @"";
        }
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            ServiceDetailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceDetailCell" forIndexPath:indexPath];
            [cell update:self.service];
            return cell;
        }
            
        case 1:
        {
            CharacteristicTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CharacteristicTableCell" forIndexPath:indexPath];
            CBCharacteristic* characteristic = self.service.characteristics[indexPath.row];
            [cell update:characteristic];
            
            cell.notifyClickedBlock = ^(CBCharacteristic* characteristic)
            {
                [self toggleNotifyForCharacteristic:characteristic indexPath:indexPath];
            };
            
            cell.readDataClickedBlock = ^(CBCharacteristic* characteristic)
            {
                [self readDataForCharacteristic:characteristic indexPath:indexPath];
            };
            
            return cell;
        }
            
        case 2:
        {
            ServiceDetailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceDetailCell" forIndexPath:indexPath];
            CBService* service = self.service.includedServices[indexPath.row];
            [cell update:service];
            return cell;
        }
            
        default:
        {
            return nil;
        }
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        CBCharacteristic* characteristic = self.service.characteristics[indexPath.row];

        [self.peripheral.peripheral uuDiscoverDescriptorsForCharacteristic:characteristic
                                                                   timeout:30.0f
                                                                completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
        {
            NSLog(@"Descriptor discovery complete for peripheral: %@, characteristic: %@, descriptors: %@, error: %@",
               peripheral, characteristic, characteristic.descriptors, error);
        }];
    }
    
    /*
    CBCharacteristic* characteristic = self.tableData[indexPath.row];
    
    [self.peripheral uuSetNotifyValue:!characteristic.isNotifying
                               forCharacteristic:characteristic
                                         timeout:30.0f
     notifyHandler:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        NSLog(@"Characteristic %@ value updated to %@", characteristic, [characteristic.value uuToHexString]);
        
        UUDispatchMain(^
        {
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        UUDispatchMain(^
        {
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];
    
    [self.peripheral uuDiscoverDescriptorsForCharacteristic:characteristic
                                              timeout:30.0f
                                           completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        NSLog(@"Descriptor discovery complete for peripheral: %@, characteristic: %@, descriptors: %@, error: %@",
              peripheral, characteristic, characteristic.descriptors, error);
    }];
    
    [self.peripheral uuReadValueForCharacteristic:characteristic
                                          timeout:30.0f
                                       completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
     {
         UUDispatchMain(^
         {
             [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
         });
     }];
    */
}

- (IBAction)onDiscoverCharacteristics:(id)sender
{
    [self.peripheral.peripheral uuDiscoverCharacteristics:nil
                                               forService:self.service
                                                  timeout:30.0f
                                               completion:^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSError * _Nullable error)
     {
         [self reloadTableData];
     }];
}

- (IBAction)onDiscoverIncludedServices:(id)sender
{
    [self.peripheral.peripheral uuDiscoverIncludedServices:nil
                                                forService:self.service
                                                   timeout:30.0f
                                                completion:^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSError * _Nullable error)
    {
        [self reloadTableData];
    }];
}

- (void) toggleNotifyForCharacteristic:(CBCharacteristic*)characteristic
                             indexPath:(NSIndexPath*)indexPath
{
    [self.peripheral.peripheral uuSetNotifyValue:!characteristic.isNotifying
                               forCharacteristic:characteristic
                                         timeout:30.0f
                                   notifyHandler:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
     {
         [self reloadRow:indexPath];
         
     }
     completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
     {
         [self reloadRow:indexPath];
     }];
}

- (void) readDataForCharacteristic:(CBCharacteristic*)characteristic
                         indexPath:(NSIndexPath*)indexPath
{
    [self.peripheral.peripheral uuReadValueForCharacteristic:characteristic
                                                     timeout:30.0f
                                                  completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        [self reloadRow:indexPath];
    }];
}

- (void) reloadTableData
{
    UUDispatchMain(^
    {
        [self.tableView reloadData];
    });
}

- (void) reloadRow:(NSIndexPath*)indexPath
{
    UUDispatchMain(^
    {
        BOOL indexPathValid = NO;
        if (indexPath.section == 0 && self.service != nil)
        {
            indexPathValid = YES;
        }
        else if (indexPath.section == 1 && indexPath.row < self.service.characteristics.count)
        {
            indexPathValid = YES;
        }
        else if (indexPath.section == 2 && indexPath.row < self.service.includedServices.count)
        {
            indexPathValid = YES;
        }
        
        if (indexPathValid)
        {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    });
}


@end
