//
//  DataCameraManager.m
//  ClickCamera
//
//  Created by DenisDbv on 19.07.13.
//  Copyright (c) 2013 denisdbv@gmail.com. All rights reserved.
//

#import "DataCameraManager.h"
#import <HRCoder/HRCoder.h>

@implementation DataCameraManager

@synthesize reportListData;

static DataCameraManager *sharedList = nil;

+ (NSString *)documentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

+ (DataCameraManager *)sharedList
{
    @synchronized(self)
    {
        if (sharedList == nil)
        {
            //if that fails, load default list from bundle
            if (sharedList == nil)
            {
                //path = [[NSBundle mainBundle] pathForResource:@"TodoList" ofType:@"plist"];
                //sharedList = [HRCoder unarchiveObjectWithFile:path];
                sharedList = [[self alloc] init];
                
                NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"TodoList.plist"];
                sharedList.reportListData = [HRCoder unarchiveObjectWithFile:path];
            }
        }
    }
	return sharedList;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        self.reportListData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)save;
{
	NSString *path = [[[self class] documentsDirectory] stringByAppendingPathComponent:@"TodoList.plist"];
	[HRCoder archiveRootObject:reportListData toFile:path];
}

@end
