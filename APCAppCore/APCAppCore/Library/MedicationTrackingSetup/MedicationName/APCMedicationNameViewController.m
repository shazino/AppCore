// 
//  APCMedicationNameViewController.m 
//  APCAppCore 
// 
// Copyright (c) 2015, Apple Inc. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APCMedicationNameViewController.h"

#import "APCMedTrackerDataStorageManager.h"
#import "APCMedTrackerMedication+Helper.h"
#import "APCMedicationNameTableViewCell.h"

#import "NSBundle+Helper.h"

#import "APCLog.h"

static  NSString  *kViewControllerName       = @"Medication Name";

static  NSString  *kMedicationNameTableCell  = @"APCMedicationNameTableViewCell";

static  CGFloat    kNumberOfSectionsInTable  =  1.0;

static  CGFloat    kSectionHeaderHeight      = 77.0;
static  CGFloat    kSectionHeaderLabelOffset = 10.0;

static  CGFloat    kAPCMedicationRowHeight   = 64.0;

@interface APCMedicationNameViewController  ( )  <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property  (nonatomic, weak)  IBOutlet  UITableView *tabulator;

@property  (nonatomic, weak)   UIBarButtonItem   *donester;
@property  (nonatomic, assign) BOOL               doneButtonWasTapped;

@property  (nonatomic, strong) NSArray <APCMedTrackerMedication *> *medicationList;

@property  (nonatomic, strong) NSIndexPath        *selectedIndex;

@property  (nonatomic, strong) UISearchController *searchController;
@property  (nonatomic, weak)   UITableViewController *resultsController;
@property  (nonatomic, strong) NSArray <APCMedTrackerMedication *> *searchResultsMedicationList;

@end

@implementation APCMedicationNameViewController


- (void)dealloc {
    _tabulator.delegate = nil;
    _tabulator.dataSource = nil;
}

#pragma  mark  -  Navigation Bar Button Action Methods

- (void)doneButtonTapped:(UIBarButtonItem *) __unused sender
{
    self.doneButtonWasTapped = YES;
    
    if (self.selectedIndex != nil) {
        if (self.delegate != nil) {
            if ([self.delegate respondsToSelector:@selector(nameController:didSelectMedicineName:)]) {
                APCMedTrackerMedication  *medication = self.medicationList[self.selectedIndex.row];
               [self.delegate nameController:self didSelectMedicineName:medication];
            }
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma  mark  -  Table View Data Source Methods

- (NSArray <APCMedTrackerMedication *> *)medicationListForTableView:(UITableView *)tableView
{
    if (tableView == self.tabulator) {
        return self.medicationList;
    }
    else {
        return self.searchResultsMedicationList;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return  kNumberOfSectionsInTable;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) __unused section
{
    NSInteger  numberOfRows = [[self medicationListForTableView:tableView] count];
    return  numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCMedicationNameTableViewCell  *cell = [tableView dequeueReusableCellWithIdentifier:kMedicationNameTableCell];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    APCMedTrackerMedication  *medication = [self medicationListForTableView:tableView][indexPath.row];
    NSString  *medicationName = medication.name;
    NSRange  range = [medicationName rangeOfString:@" ("];
    NSString  *firstString = nil;
    NSString  *secondString = nil;
    if (range.location == NSNotFound) {
        firstString = medicationName;
        cell.topLabel.hidden    = YES;
        cell.middleLabel.hidden = NO;
        cell.bottomLabel.hidden = YES;
        cell.middleLabel.text   = firstString;
    } else {
        firstString = [medicationName substringToIndex:range.location];
        secondString = [medicationName substringFromIndex:(range.location + 1)];
        cell.topLabel.hidden    = NO;
        cell.middleLabel.hidden = YES;
        cell.bottomLabel.hidden = NO;
        cell.topLabel.text      = firstString;
        cell.bottomLabel.text   = secondString;
    }
    if (self.selectedIndex != nil && tableView == self.tabulator) {
        if ([self.selectedIndex isEqual:indexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return  cell;
}

#pragma  mark  -  Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.tabulator) {
        APCMedTrackerMedication *selectedMedication = self.searchResultsMedicationList[indexPath.row];
        NSUInteger indexOfSelectedMedication = [self.medicationList indexOfObject:selectedMedication];
        if (indexOfSelectedMedication != NSNotFound) {
            self.selectedIndex = [NSIndexPath indexPathForRow:indexOfSelectedMedication inSection:0];
        }

        [self doneButtonTapped:nil];

        return;
    }

    UITableViewCell  *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if (self.selectedIndex == nil) {
        self.selectedIndex = indexPath;
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.donester.enabled = YES;
    } else {
        UITableViewCell  *oldSelectedCell = [tableView cellForRowAtIndexPath:self.selectedIndex];
        if (selectedCell == oldSelectedCell) {
            selectedCell.accessoryType = UITableViewCellAccessoryNone;
            self.selectedIndex = nil;
            self.donester.enabled = NO;
        } else {
            oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.selectedIndex = indexPath;
            self.donester.enabled = YES;
        }
    }
//    if (self.selectedIndex != nil) {
//        if (self.delegate != nil) {
//            if ([self.delegate respondsToSelector:@selector(nameController:didSelectMedicineName:)]) {
//                APCMedTrackerMedication  *medication = self.medicationList[indexPath.row];
//                [self.delegate performSelector:@selector(nameController:didSelectMedicineName:) withObject:self withObject:medication];
//            }
//        }
//    }
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat  answer = 0;

    if (section == 0 && tableView == self.tabulator) {
        answer = kSectionHeaderHeight;
    }
    return  answer;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView  *view = nil;
    
    if (section == 0 && tableView == self.tabulator) {
        CGFloat  width  = CGRectGetWidth(tableView.frame);
        CGFloat  height = [self tableView:tableView heightForHeaderInSection:section];
        CGRect   frame  = CGRectMake(0.0, 0.0, width, height);
        view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        frame.origin.x = kSectionHeaderLabelOffset;
        frame.size.width = frame.size.width - 2.0 * kSectionHeaderLabelOffset;
        UILabel  *label = [[UILabel alloc] initWithFrame:frame];
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = NSLocalizedString(@"Select the Medication You Are Currently Taking", nil);
        [view addSubview:label];
    }
    return  view;
}

- (void)setupIndexPathForMedicationDescriptor:(APCMedTrackerMedication *)aMedicationRecord
{
    for (NSUInteger  index = 0;  index < [self.self.medicationList count];  index++) {
        APCMedTrackerMedication  *medication = self.medicationList[index];
        if ([medication.name isEqualToString:aMedicationRecord.name]) {
            NSIndexPath  *path = [NSIndexPath indexPathForRow:index inSection:0];
            self.selectedIndex = path;
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return  kAPCMedicationRowHeight;
}

#pragma  mark  -  View Controller Methods

- (NSString *)title
{
    return  kViewControllerName;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.doneButtonWasTapped == NO) {
        if (self.delegate != nil) {
            if ([self.delegate respondsToSelector:@selector(nameControllerDidCancel:)]) {
                [self.delegate nameControllerDidCancel:self];
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabulator.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIBarButtonItem  *donester = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done") style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonTapped:)];
    self.donester = donester;
    self.navigationItem.rightBarButtonItem = self.donester;
    self.donester.enabled = NO;
    
    UINib  *medicationNameTableCellNib = [UINib nibWithNibName:kMedicationNameTableCell bundle:[NSBundle appleCoreBundle]];
    [self.tabulator registerNib:medicationNameTableCellNib forCellReuseIdentifier:kMedicationNameTableCell];
    
    self.medicationList = [NSArray array];
    
    [APCMedTrackerMedication fetchAllFromCoreDataAndUseThisQueue: [NSOperationQueue mainQueue]
                                                toDoThisWhenDone: ^(NSArray *arrayOfGeneratedObjects,
                                                                    NSTimeInterval  __unused operationDuration,
                                                                    NSError *error)
     {
         if (error != nil) {
             APCLogError2(error);
         } else {
             NSSortDescriptor *nameSorter = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                          ascending:YES
                                                                           selector:@selector(caseInsensitiveCompare:)];
             NSArray  *descriptors = @[ nameSorter ];
             NSArray  *sorted = [arrayOfGeneratedObjects sortedArrayUsingDescriptors:descriptors];
             
             NSMutableArray  *copyOfSorted = [sorted mutableCopy];
             APCMedTrackerMedication  *foundMedication = nil;
             NSUInteger  foundIndex = 0;
             for (NSUInteger  index = 0;  index < [copyOfSorted count];  index++) {
                 APCMedTrackerMedication  *medication = [copyOfSorted objectAtIndex:index];
                 if ([medication.name isEqualToString:@"Other"]) {
                     foundMedication = medication;
                     foundIndex = index;
                     break;
                 }
             }
             if (foundMedication != nil) {
                 [copyOfSorted removeObjectAtIndex:foundIndex];
                 [copyOfSorted addObject:foundMedication];
             }
             self.medicationList = copyOfSorted;
             
             if (self.medicationRecord != nil) {
                 [self setupIndexPathForMedicationDescriptor:self.medicationRecord];
                 self.donester.enabled = YES;
             }
            [self.tabulator reloadData];
        }
    }];

    {
        UITableViewController *resultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        resultsController.tableView.dataSource = self;
        resultsController.tableView.delegate = self;
        [resultsController.tableView registerNib:medicationNameTableCellNib forCellReuseIdentifier:kMedicationNameTableCell];

        self.searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
        self.resultsController = resultsController;

        self.searchController.searchResultsUpdater = self;

        // Install the search bar as the table header.
        self.tabulator.tableHeaderView = self.searchController.searchBar;

        // It is usually good to set the presentation context.
        self.definesPresentationContext = YES;
    }
}

#pragma mark - Search results updating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchTerms = searchController.searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"name", searchTerms];
    self.searchResultsMedicationList = [self.medicationList filteredArrayUsingPredicate:predicate];

    [self.resultsController.tableView reloadData];
}

@end
