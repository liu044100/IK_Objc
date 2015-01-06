//
//  SKNode+unarchive.h
//  IK_Objc
//
//  Created by yuchen liu on 15/1/6.
//  Copyright (c) 2015年 rain. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKNode (unarchive)
+ (instancetype)unarchiveFromFile:(NSString *)file;
@end
