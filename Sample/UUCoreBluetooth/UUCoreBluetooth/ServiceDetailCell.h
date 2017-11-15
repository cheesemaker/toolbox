//
//  ServiceDetailCell.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/25/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UUCoreBluetooth.h"

@interface ServiceDetailCell : UITableViewCell

- (void) update:(nonnull CBService*)service;

@end
