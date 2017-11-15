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

@property (strong, nonatomic, nullable) UITextView* activeEditView;

@property (assign) BOOL dismissTextViewOnScroll;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableBottomConstraint;

@end

@implementation ServiceDetailController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.peripheral.name;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

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
            
            cell.writeDataClickedBlock = ^(CBCharacteristic* characteristic, NSData* data)
            {
                [self writeDataForCharacteristic:characteristic data:data indexPath:indexPath];
            };
            
            cell.writeDataWithoutResponseClickedBlock = ^(CBCharacteristic* characteristic, NSData* data)
            {
                [self writeDataWithoutResponseForCharacteristic:characteristic data:data indexPath:indexPath];
            };
            
            cell.textViewDidBeginEditingBlock = ^(UITextView* textView)
            {
                self.dismissTextViewOnScroll = NO;
                self.activeEditView = textView;
                [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            };
            
            cell.textViewDidEndEditingBlock = ^(UITextView* textView)
            {
                self.dismissTextViewOnScroll = YES;
                self.activeEditView = nil;
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
         NSLog(@"NotifyHandler clicked");
         
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

- (void) writeDataForCharacteristic:(CBCharacteristic*)characteristic
                               data:(NSData*)data
                         indexPath:(NSIndexPath*)indexPath
{
    [self.peripheral.peripheral uuWriteValue:data
                           forCharacteristic:characteristic
                                     timeout:30.0f
                                  completion:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error)
    {
        [self reloadRow:indexPath];
    }];
}

- (void) writeDataWithoutResponseForCharacteristic:(CBCharacteristic*)characteristic
                               data:(NSData*)data
                          indexPath:(NSIndexPath*)indexPath
{
    [self.peripheral.peripheral uuWriteValueWithoutResponse:data
                                          forCharacteristic:characteristic
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


- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.dismissTextViewOnScroll)
    {
        [self.activeEditView resignFirstResponder];
    }
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.dismissTextViewOnScroll = YES;
}

- (void) handleKeyboardWillShowNotification:(NSNotification*)notification
{
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.3f animations:^
     {
         self.tableBottomConstraint.constant = keyboardFrame.size.height;
         [self.view layoutIfNeeded];
     }];
}

- (void) handleKeyboardWillHideNotification:(NSNotification*)notification
{
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.3f animations:^
     {
         self.tableBottomConstraint.constant = 0;
         [self.view layoutIfNeeded];
     }];
}


@end
