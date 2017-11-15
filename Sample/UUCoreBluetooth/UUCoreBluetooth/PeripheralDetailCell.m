//
//  PeripheralDetailCell.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/19/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "PeripheralDetailCell.h"

@interface PeripheralDetailCell ()

@property (strong, nonatomic) IBOutlet UILabel *idLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *stateLabel;
@property (strong, nonatomic) IBOutlet UILabel *rssiLabel;

@end

@implementation PeripheralDetailCell

- (void) update:(nonnull UUPeripheral*)peripheral
{
    self.idLabel.text = peripheral.identifier;
    self.nameLabel.text = peripheral.name;
    self.stateLabel.text = [NSString stringWithFormat:@"%@ (%@)", UUCBPeripheralStateToString(peripheral.peripheralState), @(peripheral.peripheralState)];
    self.rssiLabel.text = [NSString stringWithFormat:@"%@", peripheral.rssi];
}

@end
