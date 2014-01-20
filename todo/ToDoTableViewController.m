//
//  ToDoTableViewController.m
//  todo
//
//  Created by Michael Rizkalla on 1/19/14.
//  Copyright (c) 2014 yahoo. All rights reserved.
//

#import "ToDoTableViewController.h"
#import "EditableCell.h"
#import <objc/runtime.h>

@interface ToDoTableViewController ()

@property BOOL isEditing;
@property (nonatomic, strong) NSMutableArray *mToDoList;
@property (nonatomic, strong) NSString *mTodoArrayFileName;


- (IBAction)addToDoItem:(id)sender;
- (IBAction)doneEditing:(id)sender;

- (void)updateToDoItem:(UITextField *)textField;


@end

@implementation ToDoTableViewController

static char indexPathKey;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // register the custom cell NIB
    UINib *customNib = [UINib nibWithNibName:@"EditableCell" bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:@"EditableCell"];
 
    // Setup the navigation bar
    self.navigationItem.title = @"To Do List";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.isEditing = NO;
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                 target:self
                                                                                 action:@selector(addToDoItem:)];
    self.navigationItem.rightBarButtonItem = rightButton;

    //  Get the data model for this list
    //Creating a file path under iOS:
    //1) Search for the app's documents directory (copy+paste from Documentation)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //2) Create the full file path by appending the desired file name
    self.mTodoArrayFileName = [documentsDirectory stringByAppendingPathComponent:@"todolist.dat"];
    
    //Load the array
    self.mToDoList = [[NSMutableArray alloc] initWithContentsOfFile: self.mTodoArrayFileName];
    if(self.mToDoList == nil)
    {
        //Array file didn't exist... create a new one
        self.mToDoList = [[NSMutableArray alloc] initWithCapacity:10];
        
        //Fill with default values
        [self.mToDoList insertObject:@"Item Hello" atIndex:0];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.mToDoList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EditableCell";
    EditableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    //NSLog(@"row: %d", [indexPath row]);
    cell.todoItemTextField.text = [self.mToDoList objectAtIndex:[indexPath row]];
    cell.todoItemTextField.delegate = self;  // self is the ToDoTableViewController
    
    objc_setAssociatedObject(cell.todoItemTextField, &indexPathKey, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString *object = [self.mToDoList objectAtIndex:fromIndexPath.row];
    [self.mToDoList removeObjectAtIndex:fromIndexPath.row];
    [self.mToDoList insertObject:object atIndex:toIndexPath.row];
    
    BOOL success = [self.mToDoList writeToFile:self.mTodoArrayFileName atomically:YES];
    NSAssert(success, @"writeToFile failed");    
}


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)addToDoItem:(id)sender {
    // About to start adding a new item so change button to Done
    [self toggleRightNavButton];
    
    [self.mToDoList insertObject:@"" atIndex:0];
    [self.tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    EditableCell *newCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [newCell.todoItemTextField becomeFirstResponder];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // About to edit some field.  Make sure there is a done button instead of an add button
    if (!self.isEditing) {
        [self toggleRightNavButton];
    }
    return YES;

}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self updateToDoItem:textField];
    NSLog(@"inside textFieldDidEndEditing in ToDoCell");
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self updateToDoItem:textField];
    NSLog(@"inside textFieldShouldReturn in ToDoCell");
    return YES;
}

// Update the data model after an edit has taken place
- (void)updateToDoItem:(UITextField *) textField {
    NSIndexPath *indexPath = objc_getAssociatedObject(textField, &indexPathKey);

    [self.mToDoList replaceObjectAtIndex:indexPath.row withObject:textField.text];
    
    // Write the array to disk
    BOOL success = [self.mToDoList writeToFile:self.mTodoArrayFileName atomically:YES];
    NSAssert(success, @"writeToFile failed");
    
    // update the table view
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.mToDoList removeObjectAtIndex:indexPath.row];
        
        // Update the array on disk
        // Write the array to disk
        BOOL success = [self.mToDoList writeToFile:self.mTodoArrayFileName atomically:YES];
        NSAssert(success, @"writeToFile failed");
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)toggleRightNavButton {
    UIBarButtonItem *theButton;
    self.isEditing = !(self.isEditing);
    if (self.isEditing) {
        theButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(doneEditing:)];
        // Dont allow the user to delete or reorder rows while editing
        self.navigationItem.leftBarButtonItem.enabled = NO;
        
    } else {
        theButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(addToDoItem:)];
        // Allow the user to delete or reorder rows while not editing
        self.navigationItem.leftBarButtonItem.enabled = YES;

    }
    self.navigationItem.rightBarButtonItem = theButton;
}

- (void)doneEditing:(id)sender {
    [self toggleRightNavButton];
    
    // will this fire a should end editing call?
    [self.tableView endEditing:YES];
}

// When the user enters Edit mode (to delete or reoder the list) then disable the add button:
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
    if (editing) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

@end
