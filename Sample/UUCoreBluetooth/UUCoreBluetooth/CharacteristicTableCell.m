//
//  CharacteristicTableCell.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/18/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "CharacteristicTableCell.h"
#import "UUCoreBluetooth.h"
#import "UUData.h"

@import CoreBluetooth;

@interface CharacteristicTableCell ()

@property (nonnull, nonatomic, strong) CBCharacteristic* characteristic;

@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel *propsLabel;
@property (strong, nonatomic) IBOutlet UILabel *isNotifyingLabel;
@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptorCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *toggleNotifyButton;
@property (strong, nonatomic) IBOutlet UIButton *readDataButton;

@end

@implementation CharacteristicTableCell

- (void) update:(CBCharacteristic*)characteristic
{
    self.characteristic = characteristic;
    
    self.characteristicNameLabel.text = [characteristic.UUID uuCommonName];
    self.uuidLabel.text = [characteristic.UUID UUIDString];
    self.propsLabel.text = UUCBCharacteristicPropertiesToString(characteristic.properties);
    self.isNotifyingLabel.text = characteristic.isNotifying ? @"Y" : @"N";
    self.descriptorCountLabel.text = [NSString stringWithFormat:@"%@", @(characteristic.descriptors.count)];
    self.dataLabel.text = characteristic.value != nil ? [characteristic.value uuToHexString] : @"null";
    
    if (characteristic.value)
    {
        NSLog(@"Data as UTF8: %@", [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
    }
    
    if (characteristic.isNotifying)
    {
        [self.toggleNotifyButton setTitle:@"Turn Notify Off" forState:UIControlStateNormal];
    }
    else
    {
        [self.toggleNotifyButton setTitle:@"Turn Notify On" forState:UIControlStateNormal];
    }
    
    self.toggleNotifyButton.enabled = [self.characteristic uuCanToggleNotify];
    self.readDataButton.enabled = [self.characteristic uuCanReadData];
}

- (IBAction)onToggleNotify:(id)sender
{
    if (self.notifyClickedBlock)
    {
        self.notifyClickedBlock(self.characteristic);
    }
}

- (IBAction)onReadData:(id)sender
{
    if (self.readDataClickedBlock)
    {
        self.readDataClickedBlock(self.characteristic);
    }
}

@end
