//
//  Mario.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/16.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "Mario.h"

static NSString* kAnimationStand = @"mario_stand";
static NSString* kAnimationWalk = @"mario_walk";
static NSString* kAnimationJump = @"mario_jump";

static int kActionTagStand = 0;
static int kActionTagWalk = 1;
static int kActionTagJump = 2;

static const int kSpriteSpace = 1;

//ジャンプした瞬間に加わる力
static const float kJumpForceDefault = 0.7;
//ジャンプ中に加わる力
static const float kJumpForceJumping = -0.7f;

@implementation Mario {
    //1フレーム前のy位置
    CGFloat _prevY;
    CGFloat _jumpForce;
    
    BOOL _jumping;
    BOOL _walking;
    BOOL _standing;
    
    //スタート地点でのy位置
    CGFloat _baseY;
}

- (id)initwithPosition:(CGPoint)position {
    if ((self = [super initWithFile:@"mario.png"])) {
        self.position = position;
        _baseY = position.y;
        
        self.direction = DirectionRight;
        _standing = YES;
        _walking = NO;
        _jumping = NO;
        _jumpForce = kJumpForceDefault;
        
        //各種アクション用のアニメーションをキャッシュ
        CCTexture2D* texture = [[CCTextureCache sharedTextureCache] addImage:@"mario.png"];
        NSMutableArray* frames = [NSMutableArray array];
        for (int i = 0; i < 5; i++) {
            CGRect rect = CGRectMake(kSpriteSize * i + kSpriteSpace * i, 0, kSpriteSize, kSpriteSize);
            NSLog(@"%@", NSStringFromCGRect(rect));
            CCSpriteFrame* frame = [[CCSpriteFrame alloc] initWithTexture:texture rect:rect];
            [frames addObject:frame];
        }
        CCAnimation* walkAnimation = [[CCAnimation alloc] initWithSpriteFrames:[frames subarrayWithRange:NSMakeRange(0, 4)] delay:0.1f];
        [[CCAnimationCache sharedAnimationCache] addAnimation:walkAnimation name:kAnimationWalk];
        
        CCAnimation* standAnimation = [[CCAnimation alloc] initWithSpriteFrames:@[frames[0]] delay:1.0f];
        [[CCAnimationCache sharedAnimationCache] addAnimation:standAnimation name:kAnimationStand];
        
        CCAnimation* jumpAnimation = [[CCAnimation alloc] initWithSpriteFrames:@[frames[4]] delay:1.0f];
        [[CCAnimationCache sharedAnimationCache] addAnimation:jumpAnimation name:kAnimationJump];
        
        //立っている状態からスタート
        [self startStand];

        [self scheduleUpdate];
    }
    return self;
}

- (void)startStand {
    _walking = NO;
    [self stopAllActions];
    CCAnimation* anim = [[CCAnimationCache sharedAnimationCache] animationByName:kAnimationStand];
    CCAnimate* animate = [CCAnimate actionWithAnimation:anim];
    animate.tag = kActionTagStand;
    self.flipX = self.direction == DirectionRight ? 0 : 180;
    [self runAction:animate];
}

- (void)startWalk {
    _walking = YES;
    [self stopAllActions];
    CCAnimation* anim = [[CCAnimationCache sharedAnimationCache] animationByName:kAnimationWalk];
    CCRepeatForever* repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:anim]];
    repeat.tag = kActionTagWalk;
    self.flipX = self.direction == DirectionRight ? 0 : 180;
    [self runAction:repeat];
}

- (void)walking:(float)speedRatio {
    //方向転換ならアニメをリスタート
    if (self.direction == DirectionRight && speedRatio < 0) {
        self.direction = DirectionLeft;
        [self stopAllActions];
        [self startWalk];
        
    } else if (self.direction == DirectionLeft && speedRatio > 0) {
        self.direction = DirectionRight;
        [self stopAllActions];
        [self startWalk];
    }
}

- (void)startJump {
    [self stopAllActions];
    CCAnimation* anim = [[CCAnimationCache sharedAnimationCache] animationByName:kAnimationJump];
    CCAnimate* animate = [CCAnimate actionWithAnimation:anim];
    animate.tag = kActionTagJump;
    self.flipX = self.direction == DirectionRight ? 0 : 180;
    [self runAction:animate];
}

- (void)jumpWithButtonTouchHolding:(BOOL)buttonTouchHolding {
    if (buttonTouchHolding) {
        [self startJump];
        _jumping = YES;
        
    } else {
        //ボタンを離した時点でforceを変更
        if (_jumping) {
            _jumpForce = kJumpForceJumping;
        }
    }
}

- (void)update:(ccTime)delta {
    CGFloat tempY = self.position.y;

    if (_jumping) {
        //ジャンプボタン押しっぱなしであってもbaseY*2以上ジャンプしたら、forceは強制変化する
        if (self.position.y > _baseY * 2) {
            [self jumpWithButtonTouchHolding:NO];
        }
        //次フレームでのy位置
        CGFloat newY = self.position.y + (self.position.y - _prevY) + _jumpForce;
        
        if (newY <= _baseY) {
            //着地
            if (_walking) {
                [self startWalk];
            } else {
                [self startStand];
            }
            newY = _baseY;
            _jumping = NO;
            _jumpForce = kJumpForceDefault;
        }
        self.position = ccp(self.position.x, newY);
        CCLOG(@"%@", NSStringFromCGPoint(self.position));
    }
    
    _prevY = tempY;
}

@end
