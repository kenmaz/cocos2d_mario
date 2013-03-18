//
//  Mario.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/16.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "Mario.h"
#import "HelloWorldLayer.h"

static NSString* kAnimationStand = @"mario_stand";
static NSString* kAnimationWalk = @"mario_walk";
static NSString* kAnimationJump = @"mario_jump";

static int kActionTagStand = 0;
static int kActionTagWalk = 1;
static int kActionTagJump = 2;

static const int kSpriteSpace = 1;

static const int kMarioSpeed = 2;
static const int fps = 60;

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
    
    NSMutableArray* _debugCheckCollisionSprites;
    
    float elapseUpdate;
}

- (id)initWithPosition:(CGPoint)position {
    if ((self = [super initWithFile:@"mario.png"])) {
        self.position = position;
        _baseY = position.y;
        
        _debugCheckCollisionSprites = [NSMutableArray array];
        
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
    elapseUpdate += delta;
    if (elapseUpdate < 1.0 / fps) {
        return;
    } else {
        elapseUpdate = 0;
    }
    
    for (CCSprite* sprite in _debugCheckCollisionSprites) {
        sprite.color = ccWHITE;
    }
    [_debugCheckCollisionSprites removeAllObjects];
    
    CGFloat tempY = self.position.y;

    CCTMXTiledMap* map = [HelloWorldLayer sharedInstance].map;
    
    if (_jumping) {
        //ジャンプボタン押しっぱなしであってもbaseY*2以上ジャンプしたら、forceは強制変化する
        if (self.position.y > _baseY * 2) {
            [self jumpWithButtonTouchHolding:NO];
        }
        //次フレームでのy位置
        CGFloat newY = self.position.y + (self.position.y - _prevY) + _jumpForce;
        CCLOG(@"newY = %f", newY);
        CGPoint nextPos = ccp(self.position.x, newY);
        
        if ([self isCollisionWithNextMarioPos:nextPos nextMapPos:map.position]/* || newY <= _baseY*/) {
            CCLOG(@"collision! %@", NSStringFromCGPoint(self.position));
            
            if (self.position.y < newY) {
                self.position = nextPos;
                
                self.position = ccp((int)(self.position.x / map.tileSize.width) * map.tileSize.width,
                                    (int)(self.position.y / map.tileSize.height) * map.tileSize.height - (map.tileSize.height / 2));
                _prevY = self.position.y;
                
                CCLOG(@"ジャンプ中に天井に衝突, 切りのいいところに移動");
            } else {
                //地面・壁に衝突
                if (_walking) {
                    [self startWalk];
                } else {
                    [self startStand];
                }
                _prevY = self.position.y;
                
                //切りのいいところに着地
                self.position = ccp((int)(self.position.x / map.tileSize.width) * map.tileSize.width,
                                    (int)(self.position.y / map.tileSize.height) * map.tileSize.height + (map.tileSize.height / 2));
                
                //self.position = ccp(nextPos.x, nextPos.y);
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
    
    CCTMXTiledMap* map = [HelloWorldLayer sharedInstance].map;
    
    float mapWidth = map.contentSize.width;
    float screenWidth = [CCDirector sharedDirector].winSize.width;
    float centerX = screenWidth / 2;
    float mapRightEdgeX = -1 * (mapWidth - screenWidth);
    float mapLeftEdgeX = 0.0;
    
    //CCLOG(@"speed = %f, map.pos.x = %f", xSpeedRatio, map.position.x);
    
    if ((map.position.x == mapLeftEdgeX  && xSpeedRatio < 0) ||             //map左端まで表示されていて,左に移動
        (map.position.x == mapLeftEdgeX  && self.position.x < centerX) ||  //map左端まで表示されていて,マリオが左側にいる
        (map.position.x == mapRightEdgeX && 0 < xSpeedRatio) ||             //map右端まで表示されていて、右に移動
        (map.position.x == mapRightEdgeX && centerX < self.position.x))    //map右端まで表示されていて、マリオが右側にいる
    {
        //キャラを動かす
        float mx = self.position.x + (int)(xSpeedRatio * kMarioSpeed);
        
        //画面外にでないように
        if (0 <= mx && mx <= screenWidth) {
            NSLog(@"mx=%f, centerX=%f, mapX=%f", mx, centerX, map.position.x);
            
            CGPoint nextPos;
            
            if ((map.position.x == mapLeftEdgeX && 0 < xSpeedRatio && centerX < mx) ||
                (map.position.x == mapRightEdgeX && xSpeedRatio < 0 && mx < centerX)) {
                //センターを越えないように
                nextPos = ccp(centerX, self.position.y);
            } else {
                nextPos = ccp(mx, self.position.y);
            }
            
            if ([self isCollisionWithNextMarioPos:nextPos nextMapPos:map.position] == NO) {
                self.position = nextPos;
            } else {
                CCLOG(@"map can't move");
            }
        }
    } else {
        //マップを動かす
        float newMapX = map.position.x - (int)(xSpeedRatio * kMarioSpeed);
        
        //スクロールしすぎて画面外が表示されないように
        if (mapLeftEdgeX < newMapX) {
            newMapX = mapLeftEdgeX;
        }
        if (newMapX < mapRightEdgeX) {
            newMapX = mapRightEdgeX;
        }
        CGPoint nextPos = ccp(newMapX, map.position.y);
        //CCLOG(@"map x:%f", map.position.x);
        
        if ([self isCollisionWithNextMarioPos:self.position nextMapPos:nextPos] == NO) {
            map.position = nextPos;
        } else {
            CCLOG(@"map can't move");
        }
    }
    
}

//移動先ピクセルにかぶっているspriteを取得(最大で4コある), ひとつでも衝突したらNOを返して移動キャンセル(*)
- (BOOL)isCollisionWithNextMarioPos:(CGPoint)nextMarioPos nextMapPos:(CGPoint)nextMapPos {

    CCTMXTiledMap* map = [HelloWorldLayer sharedInstance].map;

    //marioの位置をmap内位置に変換
    CGPoint currPos = ccpSub(self.position, map.position);
    CGPoint nextPos = ccpSub(nextMarioPos, nextMapPos);
    CCLOG(@"current = %@, next = %@, map = %@", NSStringFromCGPoint(currPos), NSStringFromCGPoint(nextPos), NSStringFromCGPoint(map.position));

    //四方向をチェック
    int halfSize = map.tileSize.width / 2;
    CGPoint checkPoints[4];
    checkPoints[0] = ccp(nextPos.x + halfSize, nextPos.y + halfSize - 1);
    checkPoints[1] = ccp(nextPos.x - halfSize, nextPos.y + halfSize - 1);
    checkPoints[2] = ccp(nextPos.x + halfSize, nextPos.y - halfSize + 1);
    checkPoints[3] = ccp(nextPos.x - halfSize, nextPos.y - halfSize + 1);
    
    CCLOG(@"checkPoints = {%@,%@,%@,%@}",
          NSStringFromCGPoint(checkPoints[0]),
          NSStringFromCGPoint(checkPoints[1]),
          NSStringFromCGPoint(checkPoints[2]),
          NSStringFromCGPoint(checkPoints[3]));
    
    for (int i = 0; i < 4; i++) {
        CGPoint checkPoint = checkPoints[i];
        if ([self isGroundAt:checkPoint]) {
            CCLOG(@"衝突! i=%d, pt=%@", i, NSStringFromCGPoint(checkPoint));
            return YES;
        }
    }
    return NO;
}

- (CGPoint)tilePointFromPixelPoint:(CGPoint)pt {
    CCTMXTiledMap* map = [HelloWorldLayer sharedInstance].map;
    CGPoint tilePt;
    tilePt.x = (int)(pt.x / map.tileSize.width);
    tilePt.y = (int)((map.mapSize.height * map.tileSize.height - pt.y) / map.tileSize.height);
    return tilePt;
}

- (BOOL)isGroundAt:(CGPoint)pt {
    
    CCTMXTiledMap* map = [HelloWorldLayer sharedInstance].map;

    CGPoint tilePt = [self tilePointFromPixelPoint:pt];
    CCLOG(@"convert pixelPt:%@ to tilePt:%@", NSStringFromCGPoint(pt), NSStringFromCGPoint(tilePt));

    CCTMXLayer* layer = [map layerNamed:@"MainLayer"];
    int tileGID = [layer tileGIDAt:tilePt];
    if (tileGID == 0) {
        assert(0);
    }
    
    CCSprite* debugSprite = [layer tileAt:tilePt];
    debugSprite.color = ccRED;
    [_debugCheckCollisionSprites addObject:debugSprite];
    
    NSDictionary* props = [map propertiesForGID:tileGID];
    if (props) {
        NSString* isGround = props[@"isGround"];
        CCLOG(@"Ground = %@", isGround);
        
        return YES;
        
    } else {
        CCLOG(@"not Ground");
        return NO;
    }
}



@end
