//
//  MultiContentScrollView.m
//  ClickCamera
//
//  Created by DenisDbv on 17.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import "MultiContentScrollView.h"
#import <objc/runtime.h>
#import <HRCoder/HRCoder.h>

static char STRING_KEY;

@implementation MultiContentScrollView
{
    NSInteger leftSpace;
}

-(void) addDataObject:(NSString*)assetURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:assetURL] resultBlock:^(ALAsset *asset) {
        
        CGImageRef thumbnailImageRef = [asset thumbnail];
        UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
        
        /*ALAssetRepresentation *representation = [asset defaultRepresentation];
        CGImageRef originalImage = [representation fullResolutionImage];
        UIImage *original = [UIImage imageWithCGImage:originalImage];*/
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:thumbnail];
        imageView.userInteractionEnabled = YES;
        imageView.frame = CGRectMake(leftSpace*48+4, 4, 44, 44);
        CALayer *layer = [imageView layer];
        layer.cornerRadius = 4.0f;
        layer.masksToBounds = YES;
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dataTap:)];
        tap.numberOfTapsRequired = 1;
        [imageView addGestureRecognizer:tap];
        
        self.contentSize = CGSizeMake(leftSpace*48+8+44, self.frame.size.height);
        [self addSubview:imageView];
        
        leftSpace++;
        
        objc_setAssociatedObject(imageView, &STRING_KEY, assetURL, OBJC_ASSOCIATION_RETAIN);
        
    } failureBlock:^(NSError *error) {
        NSLog(@"asset failture");
    }];
}

-(void) readDataObject
{
    
}

- (void) dataTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"=>%@", (NSString *)objc_getAssociatedObject(sender.view, &STRING_KEY));
    }  
}

@end
