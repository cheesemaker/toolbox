//
//  ServiceTableCell.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/17/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ServiceTableCell : UITableViewCell

- (void) update:(CBService*)service;

@end
