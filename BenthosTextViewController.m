//
//  BenthosTextViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//	This class is based on Apple's example from the Recipes sample application, with only minor modifications

#import "BenthosTextViewController.h"
#import "BenthosCellTextView.h"

@implementation BenthosTextViewController

#define kUITextViewCellRowHeight 390.0f

- (id)initWithTitle:(NSString *)newTitle andContent:(NSString *)newContent;
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		// this title will appear in the navigation bar
		self.title = newTitle;
		content = [newContent retain];
	}
	
	return self;
}

- (void)dealloc
{	
	[content release];
	[super dealloc];
}

- (UITextView *)create_UITextView
{
	CGRect frame = CGRectMake(0.0f, 0.0f, 100.0f, 390.0f);
	
	UITextView *textView = [[[UITextView alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont fontWithName:@"Arial" size:18.0];
    textView.backgroundColor = [UIColor whiteColor];
	textView.showsVerticalScrollIndicator = YES;

	textView.editable = NO;
	textView.text = content;
	
	// note: for UITextView, if you don't like autocompletion while typing use:
	// myTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	
	return textView;
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//	return @"UITextView";
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kUITextViewCellRowHeight;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBenthosCellTextView_ID];
	
	if (cell == nil)
	{
        cell = [[[BenthosCellTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kBenthosCellTextView_ID] autorelease];
//		cell = [[[BenthosCellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kBenthosCellTextView_ID] autorelease];
	}
	
	// this cell hosts the UISwitch control
	((BenthosCellTextView *)cell).view = [self create_UITextView];
	
	return cell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

@end

