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

static const int kMarioSpeed = 2;

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
    
    CCSprite* _debugLastSprite;
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
        CGPoint nextPos = ccp(self.position.x, newY);
        
        if ([self isCollisionWithNextMarioPos:nextPos nextMapPos:self.map.position]/* || newY <= _baseY*/) {
            CCLOG(@"collision!");
            
            if (_prevY < self.position.y) {
                //ジャンプ中に天井に衝突
                _prevY = self.position.y;
                
            } else {
                //地面・壁に衝突
                if (_walking) {
                    [self startWalk];
                } else {
                    [self startStand];
                }
                //newY = _baseY;
                //nextPos = ccp(self.position.x, newY);
                self.position = nextPos;
                _jumping = NO;
                _jumpForce = kJumpForceDefault;
            }
        } else {
            self.position = nextPos;
            _prevY = tempY;
        }
        CCLOG(@"%@", NSStringFromCGPoint(self.position));
    } else {
        _prevY = tempY;
    }
}

- (void)moveToXSpeedRatio:(CGFloat)xSpeedRatio toYSpeedRatio:(CGFloat)ySpeedRatio {
    
    [self walking:xSpeedRatio];
    
    float mapWidth = self.map.contentSize.width;
    float screenWidth = [CCDirector sharedDirector].winSize.width;
    float centerX = screenWidth / 2;
    float mapRightEdgeX = -1 * (mapWidth - screenWidth);
    float mapLeftEdgeX = 0.0;
    
    //CCLOG(@"speed = %f, map.pos.x = %f", xSpeedRatio, map.position.x);
    
    if ((self.map.position.x == mapLeftEdgeX  && xSpeedRatio < 0) ||             //map左端まで表示されていて,左に移動
        (self.map.position.x == mapLeftEdgeX  && self.position.x < centerX) ||  //map左端まで表示されていて,マリオが左側にいる
        (self.map.position.x == mapRightEdgeX && 0 < xSpeedRatio) ||             //map右端まで表示されていて、右に移動
        (self.map.position.x == mapRightEdgeX && centerX < self.position.x))    //map右端まで表示されていて、マリオが右側にいる
    {
        //キャラを動かす
        float mx = self.position.x + (int)(xSpeedRatio * kMarioSpeed);
        
        //画面外にでないように
        if (0 <= mx && mx <= screenWidth) {
            NSLog(@"mx=%f, centerX=%f, mapX=%f", mx, centerX, self.map.position.x);
            
            CGPoint nextPos;
            
            if ((self.map.position.x == mapLeftEdgeX && 0 < xSpeedRatio && centerX < mx) ||
                (self.map.position.x == mapRightEdgeX && xSpeedRatio < 0 && mx < centerX)) {
                //センターを越えないように
                nextPos = ccp(centerX, self.position.y);
            } else {
                nextPos = ccp(mx, self.position.y);
            }
            if ([self isCollisionWithNextMarioPos:nextPos nextMapPos:self.map.position] == NO) {
                self.position = nextPos;
            } else {
                CCLOG(@"map can't move");
            }
        }
    } else {
        //マップを動かす
        float newMapX = self.map.position.x - (int)(xSpeedRatio * kMarioSpeed);
        
        //スクロールしすぎて画面外が表示されないように
        if (mapLeftEdgeX < newMapX) {
            newMapX = mapLeftEdgeX;
        }
        if (newMapX < mapRightEdgeX) {
            newMapX = mapRightEdgeX;
        }
        CGPoint nextPos = ccp(newMapX, self.map.position.y);
        //CCLOG(@"map x:%f", map.position.x);
        
        if ([self isCollisionWithNextMarioPos:self.position nextMapPos:nextPos] == NO) {
            self.map.position = nextPos;
        } else {
            CCLOG(@"map can't move");
        }
    }
    
}

- (BOOL)isCollisionWithNextMarioPos:(CGPoint)nextMarioPos nextMapPos:(CGPoint)nextMapPos {
    
    CGPoint currPos = ccp(abs(self.map.position.x) + self.position.x, self.position.y);
    CGPoint nextPos = ccp(abs(nextMapPos.x) + nextMarioPos.x, nextMarioPos.y);
    currPos = [[CCDirector sharedDirector] convertToGL:currPos];
    nextPos = [[CCDirector sharedDirector] convertToGL:nextPos];
    
    CCLOG(@"current = %@, next = %@, map = %@", NSStringFromCGPoint(currPos), NSStringFromCGPoint(nextPos), NSStringFromCGPoint(self.map.position));
    
    //移動先に関与するすべてのタイル(1~3個ある)
    int adjustX = 0;
    int adjustY = 0;
    
    if (currPos.x != nextPos.x) {
        adjustX = (int)currPos.x > (int)nextPos.x ? 0 : 1;
        //アンカー分半分ずらす
        CGPoint p = ccp((int)(nextPos.x - kSpriteSize / 2)/ kSpriteSize + adjustX, (int)nextPos.y / kSpriteSize);
        return [self isGroundAt:p];
    }
    if (currPos.y != nextPos.y) {
        adjustY = (int)currPos.y > (int)nextPos.y ? 0 : 1;
        CGPoint p = ccp((int)nextPos.x / kSpriteSize, (int)(nextPos.y - kSpriteSize / 2) / kSpriteSize + adjustY);
        return [self isGroundAt:p];
    }
    return NO;
}

- (BOOL)isGroundAt:(CGPoint)pt {
    CCLOG(@"check pt=%@", NSStringFromCGPoint(pt));
    
    CCTMXLayer* layer = [self.map layerNamed:@"MainLayer"];
    
    int tileGID = [layer tileGIDAt:pt];
    if (tileGID == 0) {
        assert(0);
    }
    
    if (_debugLastSprite){
        _debugLastSprite.color = ccWHITE;
    }
    
    NSDictionary* props = [self.map propertiesForGID:tileGID];
    if (props) {
        NSString* isGround = props[@"isGround"];
        CCLOG(@"Ground = %@", isGround);
        
        _debugLastSprite = [layer tileAt:pt];
        _debugLastSprite.color = ccRED;
        return YES;
        
    } else {
        CCLOG(@"not Ground");
        return NO;
    }
}



@end
