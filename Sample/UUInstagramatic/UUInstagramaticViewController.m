//
//  UUInstagramaticViewController.m
//  UUInstagramatic
//
//  Created by Jonathan Hays on 1/17/14.
//  Copyright (c) 2014 Threejacks Software. All rights reserved.
//

#import "UUInstagramaticViewController.h"
#import "UUInstagram.h"
#import "UUImageView.h"

#define kUUInstagramClientID		@"b547fd59351944fd9c2e572a01493a24"
#define kUUInstagramClientSecret	@"1e15383b36bf4f5484c1557d922f0e04"

#define kUUInstagramaticTableViewCellIdentifier @"UUInstagramaticTableViewCell"

//Stubbed out implementation here...
@implementation UUInstagramaticTableViewCell
@end

@interface UUInstagramaticViewController ()
	@property (nonatomic, strong) NSMutableArray* imageURLArray;
@end

@implementation UUInstagramaticViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
	[self.tableView registerNib:[UINib nibWithNibName:@"UUInstagramaticTableViewCell" bundle:nil] forCellReuseIdentifier:kUUInstagramaticTableViewCellIdentifier];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 160.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.imageURLArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* imageURL = [self.imageURLArray objectAtIndex:indexPath.row];
	UUInstagramaticTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kUUInstagramaticTableViewCellIdentifier forIndexPath:indexPath];
	[cell.imageView uuLoadImageFromURL:[NSURL URLWithString:imageURL] defaultImage:nil loadCompleteHandler:^(UIImageView *imageView)
	{
		
	}];
	return cell;
}

- (IBAction) onLogin:(id)sender
{
	[UUInstagram authenticate:self completionHandler:^(BOOL success, NSString *userKey)
	{
		NSLog(@"Got here!");
		[UUInstagram getPopularMedia:^(BOOL success, NSDictionary *userMedia)
		{
			[self buildMediaList:userMedia];
		}];
	}];
}

- (void) buildMediaList:(NSDictionary*)dictionary
{
	self.imageURLArray = [NSMutableArray array];
	
	NSArray* array = [dictionary objectForKey:@"data"];
	for (NSDictionary* entryDictionary in array)
	{
		NSDictionary* images = [entryDictionary objectForKey:@"images"];
		NSDictionary* standardResolutionInfo = [images objectForKey:@"standard_resolution"];
		NSString* url = [standardResolutionInfo objectForKey:@"url"];
		if (url)
		{
			[self.imageURLArray addObject:url];
		}
	}
	
	[self.tableView reloadData];
}

@end
