//
//  PPFlickrSearchViewController.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/6/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPFlickrSearchViewController.h"
#import "PPAlterImageViewController.h"
#import "PPDataFetcher.h"
#import "PPFlickrPhotoCell.h"
#import "FlickrPhoto.h"

@interface PPFlickrSearchViewController ()

@property (strong, nonatomic) NSString *currentSearchTerm;
@property (strong, nonatomic) NSArray *searchResults;
@property (nonatomic) BOOL isKeyboardShowing;
@property (strong, nonatomic) UITapGestureRecognizer * tapOffOfKeyboard;

@end

@implementation PPFlickrSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.wantsFullScreenLayout = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_cork"]];
    
    [self styleTextField];

    [self addTapGesture];
    
    [self registerNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)styleTextField
{
    UIImage *textFieldImage = [[UIImage imageNamed:@"search_field"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [self.textField setBackground:textFieldImage];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
}

-(void)addTapGesture
{
    self.tapOffOfKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnCollectionView:)];
    [self.tapOffOfKeyboard setDelegate:self];
    [self.view addGestureRecognizer:self.tapOffOfKeyboard];
}


-(void)registerNotifications
{
    //register VC as accepting of notifications named "DidLoadNewData" from dataFetchSingleton
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadTable:)
                                                 name:@"DidLoadNewData"
                                               object:nil];
    
    //register VC as accepting of notifications named "DidLoadNewData" from dataFetchSingleton
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadTable:)
                                                 name:@"useCachedData"
                                               object:nil];
    
    //register VC as accepting of notifications named "CouldNotConnectToFeed" from dataFetchSingleton
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showUIAlert:)
                                                 name:@"CouldNotConnectToFeed"
                                               object:nil];
    
    //register VC as accepting of notifications named "NoDataInFeed" from dataFetchSingleton
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showUIAlert:)
                                                 name:@"NoDataInFeed"
                                               object:nil];
    
    // Listen for keyboard appearances and disappearances
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

#pragma mark - UITextFieldDelegate methods
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    NSLog(@"we're searching");

    self.currentSearchTerm = [self stringByTrimmingTrailingWhitespaceAndNewlineCharacters: textField.text];
    
    //if search string is empty, call showUIAlert with nil param, which will be interpreted properly in the method body
    if (self.currentSearchTerm.length==0){
        [self showUIAlert:nil];
        return NO;
    }
    
    
    [[PPDataFetcher sharedInstance] beginQuery:self.currentSearchTerm];
    
    [textField resignFirstResponder];
    
    self.collectionView.hidden = YES;
    [self.activityIndicator startAnimating];
    
    return YES;
}

#pragma mark - Notification callback methods
-(void)loadTable:(NSNotification*)notif
{
    self.searchResults = [[[PPDataFetcher sharedInstance] resultsCache] objectForKey:self.currentSearchTerm][kResultsKey];
    
    //NSLog(@"Print data from cache: %@", self.searchResults);
    
    //load collectionview data
    [self.collectionView reloadData];
    
    //scroll collectionview to top
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
}

-(void)showUIAlert:(NSNotification*)notif
{
    
    NSString* alertMessage;
    
    if(notif==nil)
        alertMessage = @"You need to enter a search term!";
    
    else if([notif.name isEqualToString:@"CouldNotConnectToFeed"])
        alertMessage = @"Could not connect to the Flickr.\nPlease check internet connection.";
    
    else if([notif.name isEqualToString:@"NoDataInFeed"])
        alertMessage = [NSString stringWithFormat:@"No app results for \"%@\"!", self.currentSearchTerm];

    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [av show];
    
    [self.activityIndicator stopAnimating];
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    self.collectionView.hidden = NO;
    [self.activityIndicator stopAnimating];
    
    return [self.searchResults count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    //TODO: sort results to provide section structure?
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
   PPFlickrPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PPFlickrPhotoCell" forIndexPath:indexPath];
    cell.photo = self.searchResults[indexPath.row];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhoto *photo = self.searchResults[indexPath.row];
    [self performSegueWithIdentifier:@"flickrToEditSegue"
                              sender:photo];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{

    FlickrPhoto *photo = self.searchResults[indexPath.row];
    CGSize retval = photo.thumbnail.size.width > 0 ? photo.thumbnail.size : CGSizeMake(100, 100);
    retval.height += 35;
    retval.width += 35;
    return retval;
}


- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(50, 20, 50, 20);
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"flickrToEditSegue"]) {
        PPAlterImageViewController *alterImageViewController = segue.destinationViewController;
        alterImageViewController.flickrPhoto = sender;
    }
}

#pragma mark - keyboard notification callbacks
- (void)keyboardDidShow: (NSNotification *) notif{
    _isKeyboardShowing = YES;
}

- (void)keyboardDidHide: (NSNotification *) notif{
    _isKeyboardShowing = NO;
}


#pragma mark - gestureRecognizer delegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.tapOffOfKeyboard && self.isKeyboardShowing){
        return YES;
    }
    else if (gestureRecognizer == self.tapOffOfKeyboard && !self.isKeyboardShowing){
        return NO;
    }
    
    return NO;
}

-(void)handleTapOnCollectionView:(UITapGestureRecognizer *)recognizer
{
    [self.textField resignFirstResponder];
}

#pragma mark - some nice NSString methods for trimming whitespace
- (NSString *)string:(NSString*)original ByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet {
    
    NSRange rangeOfLastWantedCharacter = [original rangeOfCharacterFromSet:[characterSet invertedSet]
                                                               options:NSBackwardsSearch];
    if (rangeOfLastWantedCharacter.location == NSNotFound) {
        return @"";
    }
    return [original substringToIndex:rangeOfLastWantedCharacter.location+1]; // non-inclusive
}

- (NSString *)stringByTrimmingTrailingWhitespaceAndNewlineCharacters:(NSString*)original
{
    return [self string: original ByTrimmingTrailingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
