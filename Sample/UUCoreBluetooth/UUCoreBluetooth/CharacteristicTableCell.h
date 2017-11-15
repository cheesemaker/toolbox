//
//  CharacteristicTableCell.h
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/18/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^ToggleNotifyClickedBlock)(CBCharacteristic* _Nonnull characteristic);
typedef void (^ReadDataClickedBlock)(CBCharacteristic* _Nonnull characteristic);
typedef void (^WriteDataClickedBlock)(CBCharacteristic* _Nonnull characteristic, NSData* _Nonnull data);
typedef void (^EditViewBlock)(UITextView* _Nonnull textView);

@interface CharacteristicTableCell : UITableViewCell

@property (nullable, copy) ToggleNotifyClickedBlock notifyClickedBlock;
@property (nullable, copy) ReadDataClickedBlock readDataClickedBlock;
@property (nullable, copy) WriteDataClickedBlock writeDataClickedBlock;
@property (nullable, copy) WriteDataClickedBlock writeDataWithoutResponseClickedBlock;
@property (nullable, copy) EditViewBlock textViewDidBeginEditingBlock;
@property (nullable, copy) EditViewBlock textViewDidEndEditingBlock;

- (void) update:(nonnull CBCharacteristic*)characteristic;

@end
