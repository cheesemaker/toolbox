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
#import "UUString.h"

@import CoreBluetooth;

@interface CharacteristicTableCell () <UITextViewDelegate>

@property (nonnull, nonatomic, strong) CBCharacteristic* characteristic;

@property (strong, nonatomic) IBOutlet UILabel *uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel *propsLabel;
@property (strong, nonatomic) IBOutlet UILabel *isNotifyingLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptorCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *toggleNotifyButton;
@property (strong, nonatomic) IBOutlet UIButton *readDataButton;
@property (strong, nonatomic) IBOutlet UIButton *writeDataButton;
@property (strong, nonatomic) IBOutlet UIButton *wworButton;
@property (strong, nonatomic) IBOutlet UITextView *writeDataEditView;
@property (strong, nonatomic) IBOutlet UIView *editBoxBackground;

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
    self.writeDataEditView.text = characteristic.value != nil ? [characteristic.value uuToHexString] : @"";
    
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
    self.writeDataButton.enabled = [self.characteristic uuCanWriteData];
    self.wworButton.enabled = [self.characteristic uuCanWriteWithoutResponse];
    self.writeDataEditView.editable = ([self.characteristic uuCanWriteData] || [self.characteristic uuCanWriteWithoutResponse]);
    self.writeDataEditView.textColor = self.writeDataEditView.editable ? [UIColor blackColor] : [UIColor lightGrayColor];
    self.editBoxBackground.backgroundColor = self.writeDataEditView.textColor;
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

- (IBAction)onWriteData:(id)sender
{
    if (self.writeDataClickedBlock)
    {
        self.writeDataClickedBlock(self.characteristic, [self.writeDataEditView.text uuToHexData]);
    }
}

- (IBAction)onWriteDataWithoutResponse:(id)sender
{
    if (self.writeDataWithoutResponseClickedBlock)
    {
        self.writeDataWithoutResponseClickedBlock(self.characteristic, [self.writeDataEditView.text uuToHexData]);
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (self.textViewDidBeginEditingBlock)
    {
        self.textViewDidBeginEditingBlock(textView);
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.textViewDidEndEditingBlock)
    {
        self.textViewDidEndEditingBlock(textView);
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSCharacterSet* set = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEF0123456789"] invertedSet];
    NSString* filtered = [[text componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
    if ([filtered isEqualToString:text])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
