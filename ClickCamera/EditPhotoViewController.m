//
//  EditPhotoViewController.m
//  ClickCamera
//
//  Created by DenisDbv on 17.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import "EditPhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GrayscaleContrastFilter.h"

@interface EditPhotoViewController ()
@property (nonatomic, strong) NSDictionary *dataInfo;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIScrollView *filterScrollView;
@end

@implementation EditPhotoViewController
{
    UIImageView *photoImageView;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImagePicture *staticPicture;
}

@synthesize dataInfo;
@synthesize image;
@synthesize filterScrollView;
@synthesize delegate;

- (id)initWithImage:(UIImage *)aImage {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        /*if (!aImage) {
            return nil;
        }*/
        
        self.image = aImage;
        [self captureImage];
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

        return [self initWithImage:[info objectForKey:UIImagePickerControllerEditedImage]];
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
    
    CGRect mainScreenFrame = [[UIScreen mainScreen] bounds];
    filterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, mainScreenFrame.size.height, mainScreenFrame.size.width, 140)];
    filterScrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:filterScrollView];
    
    [self loadFilters];
}

-(void) viewDidAppear:(BOOL)animated
{
    [self showFilterScroll];
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
                              
                              [self.navigationController popViewControllerAnimated:YES];
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
    photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f, 42.0f, 280.0f, 280.0f)];
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

-(void) showFilterScroll
{
    CGRect sliderScrollFrame = self.filterScrollView.frame;
    sliderScrollFrame.origin.y -= self.filterScrollView.frame.size.height;
    
    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         self.filterScrollView.frame = sliderScrollFrame;
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

-(void) loadFilters {
    for(int i = 0; i < 10; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i + 1]] forState:UIControlStateNormal];
        button.frame = CGRectMake(10+i*(60+10), 5.0f, 60.0f, 60.0f);
        button.layer.cornerRadius = 7.0f;
        
        //use bezier path instead of maskToBounds on button.layer
        UIBezierPath *bi = [UIBezierPath bezierPathWithRoundedRect:button.bounds
                                                 byRoundingCorners:UIRectCornerAllCorners
                                                       cornerRadii:CGSizeMake(7.0,7.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = button.bounds;
        maskLayer.path = bi.CGPath;
        button.layer.mask = maskLayer;
        
        button.layer.borderWidth = 1;
        button.layer.borderColor = [[UIColor blackColor] CGColor];
        
        [button addTarget:self
                   action:@selector(filterClicked:)
         forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [button setTitle:@"*" forState:UIControlStateSelected];
        if(i == 0){
            [button setSelected:YES];
        }
		[self.filterScrollView addSubview:button];
	}
	[self.filterScrollView setContentSize:CGSizeMake(10 + 10*(60+10), 75.0)];
}

-(void) filterClicked:(UIButton *) sender {
    for(UIView *view in self.filterScrollView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            [(UIButton *)view setSelected:NO];
        }
    }
    
    [sender setSelected:YES];
    [self removeAllTargets];
    
    [self setFilter:sender.tag];
    
    [staticPicture addTarget:filter];
    [staticPicture processImage];
    
    self.image = [filter imageFromCurrentlyProcessedOutput];
    [photoImageView setImage:self.image];
}

-(void) setFilter:(int) index {
    switch (index) {
        case 1:{
            filter = [[GPUImageContrastFilter alloc] init];
            [(GPUImageContrastFilter *) filter setContrast:1.75];
        } break;
        case 2: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"crossprocess"];
        } break;
        case 3: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
        } break;
        case 4: {
            filter = [[GrayscaleContrastFilter alloc] init];
        } break;
        case 5: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
        } break;
        case 6: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
        } break;
        case 7: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"yellow-red"];
        } break;
        case 8: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
        } break;
        case 9: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"purple-green"];
        } break;
        default:
            filter = [[GPUImageFilter alloc] init];
            break;
    }
}

-(void) removeAllTargets
{
    [staticPicture removeAllTargets];
    [filter removeAllTargets];
}

-(void) captureImage
{
    staticPicture = [[GPUImagePicture alloc] initWithImage:self.image
                                       smoothlyScaleOutput:YES];
}

@end
