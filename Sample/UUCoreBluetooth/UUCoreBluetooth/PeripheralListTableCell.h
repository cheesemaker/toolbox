//
//  PeripheralTableCell.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/9/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UUCoreBluetooth.h"


@interface PeripheralListTableRow : NSObject

@property (nonnull, nonatomic, strong) UUPeripheral* peripheral;
@property (assign) BOOL isExpanded;

@end


@interface PeripheralListTableCell : UITableViewCell

- (void) update:(nonnull PeripheralListTableRow*)cellData;

@end
