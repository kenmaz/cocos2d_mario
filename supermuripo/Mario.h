//
//  Mario.h
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/16.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    DirectionLeft,
    DirectionRight
} Direction;

@interface Mario : CCSprite

@property Direction direction;

- (id)initwithPosition:(CGPoint)position;
- (void)jumpWithButtonTouchHolding:(BOOL)buttonTouchHolding;

- (void)startStand;
- (void)startWalk;
- (void)walking:(float)speedRatio;
- (void)startJump;
@end
