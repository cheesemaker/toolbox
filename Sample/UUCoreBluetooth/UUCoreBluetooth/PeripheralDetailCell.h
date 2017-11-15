//
//  PeripheralDetailCell.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/19/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UUCoreBluetooth.h"

@interface PeripheralDetailCell : UITableViewCell

- (void) update:(nonnull UUPeripheral*)peripheral;

@end
