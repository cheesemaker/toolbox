//
//  ServiceTableCell.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/17/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "ServiceTableCell.h"

@interface ServiceTableCell ()

@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel *isPrimaryLabel;
@property (strong, nonatomic) IBOutlet UILabel *includedServicesCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *characteristicCountLabel;

@end

@implementation ServiceTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) update:(CBService*)service
{
    self.uuidLabel.text = [service.UUID UUIDString];
    self.isPrimaryLabel.text = service.isPrimary ? @"Y" : @"N";
    self.includedServicesCountLabel.text = [NSString stringWithFormat:@"%@", @(service.includedServices.count)];
    self.characteristicCountLabel.text = [NSString stringWithFormat:@"%@", @(service.characteristics.count)];
}

@end
