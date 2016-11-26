//
//  ServiceDetailController.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/18/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UUCoreBluetooth.h"

@interface ServiceDetailController : UIViewController

@property (nonnull, nonatomic, strong) UUPeripheral* peripheral;
@property (nonnull, nonatomic, strong) CBService* service;
@end
