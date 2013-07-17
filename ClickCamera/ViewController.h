//
//  ViewController.h
//  ClickCamera
//
//  Created by denisdbv@gmail.com on 16.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiContentScrollView.h"
#import "EditPhotoViewController.h"

@interface ViewController : UIViewController <EditPhotoViewDelegate>

@property (nonatomic, strong) IBOutlet MultiContentScrollView *scrollView;

@end
