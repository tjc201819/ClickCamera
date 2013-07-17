//
//  EditPhotoViewController.h
//  ClickCamera
//
//  Created by DenisDbv on 17.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditPhotoViewDelegate <NSObject>
-(void) addDataToScrollReportArray:(ALAsset*)asset;
@end

@interface EditPhotoViewController : UIViewController

@property (nonatomic, retain) id delegate;

- (id)initWithImage:(UIImage *)aImage;
- (id)initWithDictionary:(NSDictionary *)info;

@end
