//
//  JumpButton.h
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/16.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef void (^ButtonDidBeginSelected)();
typedef void (^ButtonDidEndSelected)();

@interface JumpButton : CCMenuItemImage
@property (copy) ButtonDidBeginSelected beginTouchBlock;
@property (copy) ButtonDidEndSelected endTouchBlock;

@end
