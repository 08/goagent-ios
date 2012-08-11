//
//  GSettingViewController.m
//  goagent-ios
//
//  Created by hewig on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GSettingViewController.h"
#import "GConfig.h"
#import "NSTask.h"

@implementation GSettingViewController
@synthesize settingSections,settingDic,settingTableView,titleBar,BackBtn,EditBtn,docInteractionController;

-(void)awakeFromNib
{
    [self prepareSettingForDisplay];
}

-(void)dealloc
{
    if(iniDic)
        iniparser_freedict(iniDic);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [settingSections count];
}

-(NSInteger)tableView:(UITableView *)tabbleView numberOfRowsInSection:(NSInteger)section
{
    return [[settingDic objectForKey:[settingSections objectAtIndex:section]] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
    int currentRow =[indexPath row];
    int currentSection = [indexPath section];
    int itemTag = (int)pow(10, currentSection+1)+currentRow;
    
    NSString* key = [settingSections objectAtIndex:currentSection];
    NSArray* contents = [settingDic objectForKey:key];
    NSDictionary* item = [contents objectAtIndex:currentRow];
    
    if ([key isEqualToString:KEY_SETTING_BASIC])
    {
        UITextField* valueField = [[UITextField alloc] initWithFrame:CGRectMake(0,10,125,25)];
        valueField.adjustsFontSizeToFitWidth = NO;
        valueField.backgroundColor = [UIColor clearColor];
        valueField.autocorrectionType = UITextAutocorrectionTypeNo;
        valueField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        valueField.textAlignment = UITextAlignmentRight;
        valueField.keyboardType = UIKeyboardTypeDefault;
        valueField.returnKeyType = UIReturnKeyDone;
        valueField.clearButtonMode = UITextFieldViewModeNever;
        valueField.delegate = self;
        valueField.text = [item objectForKey:[NSString stringWithFormat:@"%@_%d_value",key,currentRow]];
        valueField.tag = itemTag;
        cell.accessoryView = valueField;
        cell.textLabel.text = [item objectForKey:[NSString stringWithFormat:@"%@_%d_key",key,currentRow]];
    }
    else if ([key isEqualToString:KEY_SETTING_ADVANCED])
    {
        UIButton *button = [[UIButton alloc] initWithFrame:[cell frame]];
        [button addTarget:self action:@selector(performPressAciton:) forControlEvents:UIControlEventTouchUpInside];
        [button setTag:itemTag];
        [button setTitle:[item objectForKey:[NSString stringWithFormat:@"%@_%d_value",key,currentRow]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        [cell.contentView addSubview:button];
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [settingSections objectAtIndex:section];
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    int textTag = [textField tag];
    int section=0,row=0;
    row = textTag % 10;
    while (textTag)
    {
        textTag = textTag / 10;
        if (textTag>1)
        {
            section+=1;
        }
    }
    
    NSLog(@"tag is %d,section is %d,row is %d",textTag,section,row);
    
    
    NSString* key = [settingSections objectAtIndex:section];
    NSArray* contents = [settingDic objectForKey:key];
    NSDictionary* item = [contents objectAtIndex:row];
    
    [item setValue:[textField text] forKey:[NSString stringWithFormat:@"%@_%d_value",key,row]];
    char *iniKey = NULL;
    switch ([textField tag]) {
        case 10:
            iniKey="gae:appid";
            break;
        case 11:
            iniKey="gae:profile";
            break;
        case 12:
            iniKey="pac:enable";
            break;
        default:
            break;
    }
    if (iniKey)
    {
        iniparser_set(iniDic, iniKey,[[textField text] UTF8String]);
        FILE* fp = fopen([[[NSBundle mainBundle] pathForResource:CONFIG_FILE_NAME
                                                         ofType:CONFIG_FILE_TYPE
                                                     inDirectory:GOAGENT_LOCAL_PATH] UTF8String],"w+");
        iniparser_dump_ini(iniDic,fp);
        fclose(fp);
    }
    
    [textField resignFirstResponder];
    return YES;
}

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}

-(dictionary*)getGoAgentSettings
{
    NSString* iniFile = [[NSBundle mainBundle] pathForResource:CONFIG_FILE_NAME
                                                        ofType:CONFIG_FILE_TYPE
                                                   inDirectory:GOAGENT_LOCAL_PATH];
    if (iniDic)
    {
        return iniDic;
    }
    else
    {
        iniDic = iniparser_load([iniFile UTF8String]);
        return iniDic;
    }
}

-(void)prepareSettingForDisplay
{
    self.settingSections = [[NSMutableArray alloc] init];
    self.settingDic = [[NSMutableDictionary alloc] init];
    
    [self getGoAgentSettings];
    
    //basic settings
    NSMutableDictionary* appidDic = [NSMutableDictionary dictionaryWithObjects:
                                     [NSArray arrayWithObjects:KEY_SETTING_APPID,[NSString stringWithUTF8String:iniparser_getstring(iniDic, "gae:appid", NULL)],nil]
                                                                       forKeys:
                                     [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@_0_key",KEY_SETTING_BASIC], [NSString stringWithFormat:@"%@_0_value",KEY_SETTING_BASIC],nil]
                                     ];
    
    NSMutableDictionary* profileDic = [NSMutableDictionary dictionaryWithObjects:
                                       [NSArray arrayWithObjects:KEY_SETTING_PROFILE,[NSString stringWithUTF8String:iniparser_getstring(iniDic, "gae:profile", NULL)],nil]
                                                                         forKeys:
                                       [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@_1_key",KEY_SETTING_BASIC], [NSString stringWithFormat:@"%@_1_value",KEY_SETTING_BASIC],nil]
                                       ];
    
    NSMutableDictionary* pacDic = [NSMutableDictionary dictionaryWithObjects:
                                   [NSArray arrayWithObjects:KEY_SETTING_PAC,[NSString stringWithUTF8String:iniparser_getstring(iniDic, "pac:enable", NULL)],nil]
                                                                     forKeys:
                                   [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@_2_key",KEY_SETTING_BASIC], [NSString stringWithFormat:@"%@_2_value",KEY_SETTING_BASIC],nil]
                                   ];
    
    NSArray* basicArray = [NSArray arrayWithObjects:appidDic,profileDic,pacDic,nil];
    
    [self.settingDic setObject:basicArray forKey:KEY_SETTING_BASIC];
    
    //advanced settings
    NSMutableDictionary* sysproxyDic = [NSMutableDictionary dictionaryWithObjects:
                                        [NSArray arrayWithObjects:KEY_SETTING_SET_SYSPROXY,KEY_SETTING_SET_SYSPROXY,nil]
                                                                          forKeys:
                                        [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@_0_key",KEY_SETTING_ADVANCED], [NSString stringWithFormat:@"%@_0_value",KEY_SETTING_ADVANCED],nil]
                                 ];
    
    NSArray* advancedArray = [NSArray arrayWithObject:sysproxyDic];
    
    [self.settingDic setObject:advancedArray forKey:KEY_SETTING_ADVANCED];
    
    [self.settingSections addObject:KEY_SETTING_BASIC];
    [self.settingSections addObject:KEY_SETTING_ADVANCED];
}

-(IBAction)performBackAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)performEditAction:(id)sender
{
    NSString* iniFile = [[NSBundle mainBundle] pathForResource:CONFIG_FILE_NAME
                                                        ofType:CONFIG_FILE_TYPE
                                                   inDirectory:GOAGENT_LOCAL_PATH];
    
    NSURL* ifileReq = [NSURL URLWithString:[NSString stringWithFormat:@"ifile://localhost%@",iniFile]];
    
    if (![[UIApplication sharedApplication] openURL:ifileReq])
    {
        [self setupDocumentControllerWithURL:[NSURL fileURLWithPath:iniFile]];
        
        if (![self.docInteractionController presentOpenInMenuFromRect:CGRectZero
                                                               inView:self.view.window
                                                             animated:YES])
        {
            UIAlertView* alert = [[UIAlertView alloc] init];
            [alert setTitle:@"GoAgent for iOS"];
            [alert setMessage:[NSString stringWithFormat:@"Sorry, No other App can edit %@.%@",CONFIG_FILE_NAME,CONFIG_FILE_TYPE]];
            [alert addButtonWithTitle:@"OK"];
            [alert show];
        }
    }
}

-(void)performPressAciton:(id)sender
{
    NSString* workingDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* changeSh = [[NSBundle mainBundle] pathForResource:CHANGE_SYSPROXY_SCRIPT
                                                          ofType:CONTROL_SCRIPT_TYPE
                                                     inDirectory:GOAGENT_LOCAL_PATH];
    
    NSTask* task = [NSTask alloc];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:[NSArray arrayWithObject:changeSh]];
    [task setCurrentDirectoryPath:workingDir];
    [task launch];
}

@end
