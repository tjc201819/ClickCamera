//
//  ViewController.m
//  ClickCamera
//
//  Created by denisdbv@gmail.com on 16.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

//http://stackoverflow.com/questions/10954380/save-photos-to-custom-album-in-iphones-photo-library

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Photo" style:UIBarButtonItemStyleBordered target:self action:@selector(photoCaptureButtonAction:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)photoCaptureButtonAction:(id)sender {
    BOOL cameraDeviceAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL photoLibraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if (cameraDeviceAvailable && photoLibraryAvailable) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Снять фото", @"Снять видео", @"Выбрать фото", nil];
        [actionSheet showInView:self.view];
    } else {
        [self shouldPresentPhotoCaptureController];
    }
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"Cancel");
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissModalViewControllerAnimated:NO];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library addAssetsGroupAlbumWithName:dateString resultBlock:^(ALAssetsGroup *group) {   //!!! Пока создается альбом уже идет выполнение нижнего блока
        NSLog(@"added album:%@", dateString);
    }
    failureBlock:^(NSError *error) {
         NSLog(@"error adding album");
    }];
    
    __block ALAssetsGroup* groupToAddTo;
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:dateString]) {
                                        NSLog(@"found album %@", dateString);
                                        groupToAddTo = group;
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
    
    if( [info objectForKey:UIImagePickerControllerEditedImage] != nil)  {
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        
        [library writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"ERROR: the image failed to be written");
            }
            else {
                NSLog(@"Photo saved (%@)", assetURL);
                
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             [groupToAddTo addAsset:asset];
                             NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], dateString);
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            }
        }];
        
    } else if([info objectForKey:UIImagePickerControllerMediaURL] != nil) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"ERROR: the video failed to be written");
            }
            else {
                NSLog(@"Video saved (%@)", assetURL);
                
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             [groupToAddTo addAsset:asset];
                             NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], dateString);
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            }
        }];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self shouldStartPhotoCameraController];
    } else if (buttonIndex == 1) {
        [self shouldStartVideoCameraController];
    } else if (buttonIndex == 2) {
        [self shouldStartPhotoLibraryPickerController];
    }
}

- (BOOL)shouldStartPhotoCameraController {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = YES;
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = (id)self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

- (BOOL)shouldStartVideoCameraController {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeMovie];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
    } else {
        return NO;
    }
    
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = (id)self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

- (BOOL)shouldPresentPhotoCaptureController {
    BOOL presentedPhotoCaptureController = [self shouldStartPhotoCameraController];
    
    if (!presentedPhotoCaptureController) {
        presentedPhotoCaptureController = [self shouldStartPhotoLibraryPickerController];
    }
    
    return presentedPhotoCaptureController;
}

- (BOOL)shouldStartPhotoLibraryPickerController {
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
               && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = (id)self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

@end
