//
//  UUInstagramaticViewController.h
//  UUInstagramatic
//
//  Created by Jonathan Hays on 1/17/14.
//  Copyright (c) 2014 Threejacks Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UUInstagramaticTableViewCell : UITableViewCell
	@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@end

@interface UUInstagramaticViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
	@property (nonatomic, strong) IBOutlet UITableView* tableView;

	- (IBAction) onLogin:(id)sender;
@end
