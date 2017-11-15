//
//  ServiceListController.m
//  UUCoreBluetooth
//
//  Created by Ryan DeVore on 11/17/16.
//  Copyright © 2016 UUToolbox. All rights reserved.
//

#import "ServiceListController.h"
#import "ServiceTableCell.h"
#import "ServiceDetailController.h"
#import "UUMacros.h"

@interface ServiceListController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray* tableData;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ServiceListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 30;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.peripheral.name;
    
    [self updatePeripheralState];
    
    if (self.peripheral.peripheralState != CBPeripheralStateConnected)
    {
        /*
        [[UUCoreBluetooth sharedInstance] connectPeripheral:self.peripheral
                                                    timeout:30.0f
                                                  connected:^(UUPeripheral * _Nonnull peripheral)
        {
            [self updatePeripheralState];
            [self scanForServices];
        }
        disconnected:^(UUPeripheral * _Nonnull peripheral, NSError * _Nullable error)
        {
            [self updatePeripheralState];
        
        }];*/
    }
    else
    {
        [self scanForServices];
    }
}

- (void) scanForServices
{
    [self.peripheral.peripheral uuDiscoverServices:nil
                                           timeout:30.0f
                                        completion:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error)
    {
        UUDispatchMain(^
        {
            self.tableData = peripheral.services;
            [self.tableView reloadData];
        });
    }];
}

- (void) updatePeripheralState
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        //self.navigationItem.prompt = UUCBPeripheralStateToString(self.peripheral.peripheralState);
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([@"showServiceDetail" isEqualToString:segue.identifier])
    {
        ServiceDetailController* c = [segue destinationViewController];
        //c.peripheral = self.peripheral;
        c.service = sender;
    }
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServiceTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceTableCell" forIndexPath:indexPath];
    CBService* service = self.tableData[indexPath.row];
    [cell update:service];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBService* service = self.tableData[indexPath.row];
    [self performSegueWithIdentifier:@"showServiceDetail" sender:service];
}
    
    

@end
