//
//  PeripheralTableCell.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/9/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "PeripheralListTableCell.h"

@implementation PeripheralListTableRow

@end


@interface PeripheralListTableCell ()

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *idLabel;
@property (strong, nonatomic) IBOutlet UILabel *stateLabel;
@property (strong, nonatomic) IBOutlet UILabel *rssiLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeSinceLastBeaconLabel;

@end

@implementation PeripheralListTableCell

- (void) update:(PeripheralListTableRow*)cellData
{
    UUPeripheral* peripheral = cellData.peripheral;
    
    self.nameLabel.text = peripheral.name;
    self.idLabel.text = peripheral.identifier;
    self.rssiLabel.text =  [peripheral.rssi stringValue];
    self.stateLabel.text = UUCBPeripheralStateToString(peripheral.peripheralState);
    self.timeSinceLastBeaconLabel.text = [NSString stringWithFormat:@"%.3f", [[NSDate date] timeIntervalSinceDate:peripheral.lastAdvertisementTime]];
    
    if (cellData.isExpanded)
    {
        self.nameLabel.text = [peripheral.name stringByAppendingString:@" +++ "];
    }
}

@end
