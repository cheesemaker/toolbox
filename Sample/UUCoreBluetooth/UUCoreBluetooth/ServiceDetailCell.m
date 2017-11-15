//
//  ServiceDetailCell.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/25/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "ServiceDetailCell.h"

@interface ServiceDetailCell ()

@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel *isPrimaryLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@end


@implementation ServiceDetailCell

- (void) update:(nonnull CBService*)service
{
    self.nameLabel.text = [service.UUID uuCommonName];
    self.uuidLabel.text = [service.UUID UUIDString];
    self.isPrimaryLabel.text = service.isPrimary ? @"Y" : @"N";
}

@end
