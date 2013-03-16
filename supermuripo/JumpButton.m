//
//  JumpButton.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/16.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "JumpButton.h"


@implementation JumpButton

-(void) selected
{
    [super selected];
    self.beginTouchBlock();
}

-(void) unselected
{
	[super unselected];
    self.endTouchBlock();
}

@end
