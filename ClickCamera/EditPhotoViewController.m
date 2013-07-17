//
//  EditPhotoViewController.m
//  ClickCamera
//
//  Created by DenisDbv on 17.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import "EditPhotoViewController.h"

@interface EditPhotoViewController ()
@property (nonatomic, strong) NSDictionary *dataInfo;
@property (nonatomic, strong) UIImage *image;
@end

@implementation EditPhotoViewController
@synthesize dataInfo;
@synthesize image;
@synthesize delegate;

- (id)initWithImage:(UIImage *)aImage {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (!aImage) {
            return nil;
        }
        
        self.image = aImage;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)info
{
    dataInfo = info;
    
    if( [info objectForKey:UIImagePickerControllerEditedImage] != nil)
    {
        return [self initWithImage:[info objectForKey:UIImagePickerControllerEditedImage]];
    }
    else if([info objectForKey:UIImagePickerControllerMediaURL] != nil)
    {
        [self saveVideoToAlbum:[self currentDateString] :[info objectForKey:UIImagePickerControllerMediaURL]];
        
        return nil;
    }
    
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.navigationItem setHidesBackButton:YES];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonAction:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(addButtonAction:)];
    
    [self addImageToView];
}

-(NSString*) currentDateString
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    return dateString;
}

-(void) saveImageToAlbum:(NSString*)albumName :(UIImage*)newImage processWithBlock:(void(^)())block
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group)
    {
        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
        {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName])
            {
                [library writeImageToSavedPhotosAlbum:newImage.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"ERROR: the image failed to be written");
                    }
                    else {
                        NSLog(@"Photo saved (%@)", assetURL);
                        
                        [library assetForURL:assetURL resultBlock:^(ALAsset *asset)
                        {
                            [group addAsset:asset];
                            [self addDataToScroll:asset];
                                     
                            NSLog(@"new file by path (%@)", [asset defaultRepresentation].url);
                            NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                            
                            if(block != nil) block();
                        }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
                    }
                }];
            }
        }
        failureBlock:^(NSError* error) {
            NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
        }];
    }
    failureBlock:^(NSError *error) {
        NSLog(@"error adding album");
    }];
}

-(void) saveVideoToAlbum:(NSString*)albumName :(NSURL*)videoURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    [library addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group)
     {
         [library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
          {
              if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName])
              {
                  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
                      if (error) {
                          NSLog(@"ERROR: the video failed to be written");
                      }
                      else {
                          NSLog(@"Video saved (%@)", assetURL);
                          
                          [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                              [group addAsset:asset];
                              [self addDataToScroll:asset];
                              
                              NSLog(@"new file by path (%@)", [asset defaultRepresentation].url);
                              NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                          }
                          failureBlock:^(NSError* error) {
                              NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                          }];
                      }
                  }];
              }
          }
          failureBlock:^(NSError* error) {
              NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
          }];
    }
    failureBlock:^(NSError *error) {
        NSLog(@"error adding album");
    }];
}

-(void) addDataToScroll:(ALAsset*)asset
{
    if([delegate respondsToSelector:@selector(addDataToScrollReportArray:)])
    {
        [delegate addDataToScrollReportArray:asset];
    }
}

-(void) addImageToView
{
    UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f, 42.0f, 280.0f, 280.0f)];
    [photoImageView setBackgroundColor:[UIColor blackColor]];
    [photoImageView setImage:self.image];
    [photoImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    CALayer *layer = photoImageView.layer;
    layer.masksToBounds = NO;
    layer.shadowRadius = 3.0f;
    layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    layer.shadowOpacity = 0.5f;
    layer.shouldRasterize = YES;
    
    [self.view addSubview:photoImageView];
}

- (void)addButtonAction:(id)sender
{
    [self saveImageToAlbum:[self currentDateString] :image processWithBlock:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)cancelButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
