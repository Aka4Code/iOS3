/**
 * @file PasscodeTableViewController.m
 * @brief View controller that shows passcode options
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "PasscodeTableViewController.h"
#import "LTHPasscodeViewController.h"
#import "Helper.h"

#import <LocalAuthentication/LAContext.h>

@interface PasscodeTableViewController () {
    BOOL wasPasscodeAlreadyEnabled;
}

@property (weak, nonatomic) IBOutlet UILabel *turnOnOffPasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *turnOnOffPasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *simplePasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *simplePasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *eraseLocalDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *eraseLocalDataSwitch;
@property (weak, nonatomic) IBOutlet UILabel *touchIDLabel;
@property (weak, nonatomic) IBOutlet UISwitch *touchIDSwitch;

@end

@implementation PasscodeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"passcode", nil)];
    [self.turnOnOffPasscodeLabel setText:AMLocalizedString(@"passcode", nil)];
    [self.changePasscodeLabel setText:AMLocalizedString(@"changePasscodeLabel", @"Change passcode")];
    [self.simplePasscodeLabel setText:AMLocalizedString(@"simplePasscodeLabel", @"Simple passcode")];
    [self.touchIDLabel setText:@"Touch ID"];
    [self.eraseLocalDataLabel setText:AMLocalizedString(@"eraseAllLocalDataLabel", @"Erase all local data")];
    
    wasPasscodeAlreadyEnabled = [LTHPasscodeViewController doesPasscodeExist];
    [[LTHPasscodeViewController sharedUser] setHidesCancelButton:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.turnOnOffPasscodeSwitch setOn:doesPasscodeExist];
    if (doesPasscodeExist) {
        [self.simplePasscodeSwitch setOn:[[LTHPasscodeViewController sharedUser] isSimple]];
        [self.touchIDSwitch setOn:[[LTHPasscodeViewController sharedUser] allowUnlockWithTouchID]];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
            [self.eraseLocalDataSwitch setOn:YES];
            [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        } else {
            [self.eraseLocalDataSwitch setOn:NO];
            
            if (!wasPasscodeAlreadyEnabled) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsEraseAllLocalDataEnabled];
                [self.eraseLocalDataSwitch setOn:YES];
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
                wasPasscodeAlreadyEnabled = YES;
            }
        }
        
    } else {
        [self.simplePasscodeSwitch setOn:NO];
        [self.touchIDSwitch setOn:NO];
        [self.eraseLocalDataSwitch setOn:NO];
    }
    
    [self.tableView reloadData];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
        
#pragma mark - Private
        
- (void)eraseLocalData {
    BOOL eraseLocalDataEnaled = [[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled];
    
    if (eraseLocalDataEnaled) {
        [self.eraseLocalDataSwitch setOn:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
    } else {
        [self.eraseLocalDataSwitch setOn:NO];
    }
}

- (BOOL)isTouchIDAvailable {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    }
    return NO;
}

#pragma mark - IBActions

- (IBAction)passcodeSwitchValueChanged:(UISwitch *)sender {
    if (![LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
    } else {
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
    }
}

- (IBAction)simplePasscodeSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setIsSimple:self.simplePasscodeSwitch.isOn inViewController:self asModal:YES];
}

- (IBAction)eraseLocalDataSwitchValueChanged:(UISwitch *)sender {
    BOOL isEraseLocalData = ![[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled];
    
    [[NSUserDefaults standardUserDefaults] setBool:isEraseLocalData forKey:kIsEraseAllLocalDataEnabled];
    if (isEraseLocalData) {
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        [self.eraseLocalDataSwitch setOn:YES animated:YES];
    } else {
        [self.eraseLocalDataSwitch setOn:NO animated:YES];
    }
}

- (IBAction)touchIDSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setAllowUnlockWithTouchID:sender.isOn];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL doesPasscodeExist = [LTHPasscodeViewController doesPasscodeExist];
    [self.changePasscodeLabel setEnabled:doesPasscodeExist];
    [self.simplePasscodeLabel setEnabled:doesPasscodeExist];
    [self.simplePasscodeSwitch setEnabled:doesPasscodeExist];
    [self.eraseLocalDataLabel setEnabled:doesPasscodeExist];
    [self.eraseLocalDataSwitch setEnabled:doesPasscodeExist];
    [self.touchIDSwitch setEnabled:doesPasscodeExist];
    [self.touchIDLabel setEnabled:doesPasscodeExist];

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    switch (section) {
        case 0:
            if ([self isTouchIDAvailable]) {
                numberOfRows = 4;
            } else {
                numberOfRows = 3;
            }
            break;
            
        case 1:
            numberOfRows = 1;
            break;
    }
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter = @"";
    
    if (section == 1) {
        titleForFooter = AMLocalizedString(@"failedAttempstSectionTitle", @"Log out and erase all local data on MEGA’s app after 10 failed passcode attempts");
    }
    
    return titleForFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 1)) {
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
