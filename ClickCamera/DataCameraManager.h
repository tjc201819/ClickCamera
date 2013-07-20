//
//  DataCameraManager.h
//  ClickCamera
//
//  Created by DenisDbv on 19.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataCameraManager : NSObject <NSCoding>

@property (nonatomic, retain) NSMutableArray *reportListData;

+ (DataCameraManager *)sharedList;
- (void)save;

@end
