//
//  HelloWorldLayer.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/14.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "Mario.h"
#import "JumpButton.h"

static const int kTileMapNode = 1;
static const int kMarioNode = 2;

static const int kMarioSpeed = 2;
static const int kSpriteSize = 16;

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer {
    ZJoystick *_joystick;
    CCSprite* _mario;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init]) ) {
		
        //背景タイル
        CCTMXTiledMap* tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"mario.tmx"];
        [self addChild:tileMap z:-1 tag:kTileMapNode];

        //マリオ
        Mario* mario = [[Mario alloc] initwithPosition:ccp([CCDirector sharedDirector].winSize.width / 2, kSpriteSize * 4.5)];
        [self addChild:mario z:100 tag:kMarioNode];
        
        //ジョイスティック
        _joystick = [ZJoystick joystickNormalSpriteFile:@"cursor.png" selectedSpriteFile:@"cursor.png" controllerSpriteFile:@"Joystick_norm.png"];
        _joystick.position = ccp(_joystick.contentSize.width/2, _joystick.contentSize.height/2);
        _joystick.delegate = self;
        _joystick.speedRatio = 2.0f;
        _joystick.joystickRadius = 100.0f;
        [self addChild:_joystick];
        
        //ジャンプボタン
        JumpButton* jumpButton = [JumpButton itemWithNormalImage:@"button.png" selectedImage:@"button.png" target:self selector:@selector(starButtonTapped:)];
        float screenWidth = [CCDirector sharedDirector].winSize.width;
        jumpButton.position = ccp(screenWidth - jumpButton.contentSize.width / 2, jumpButton.contentSize.height / 2);
        
        __block Mario* targetMario = mario;
        jumpButton.beginTouchBlock = ^{
            NSLog(@"begin");
            [targetMario jumpWithButtonTouchHolding:YES];
        };
        jumpButton.endTouchBlock = ^{
            NSLog(@"end");
            [targetMario jumpWithButtonTouchHolding:NO];
        };
        CCMenu *buttonBase = [CCMenu menuWithItems:jumpButton, nil];
        buttonBase.position = CGPointZero;
        [self addChild:buttonBase];
	}
	return self;
}

- (void)starButtonTapped:(id)sender {
    NSLog(@"button");
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (CGPoint)locationFromTouches:(NSSet*)touches {
    UITouch* touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:[touch view]];
    return [[CCDirector sharedDirector] convertToGL:touchLocation];
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

#pragma mark - //JoystickDelegate

//ジョイスティック押した
-(void)joystickControlBegan {
    Mario* mario = (Mario*)[self getChildByTag:kMarioNode];
    [mario startWalk];
}

//ジョイスティック離した
-(void)joystickControlEnded {
    Mario* mario = (Mario*)[self getChildByTag:kMarioNode];
    [mario startStand];
}

//ジョイスティック操作
-(void)joystickControlDidUpdate:(id)joystick toXSpeedRatio:(CGFloat)xSpeedRatio toYSpeedRatio:(CGFloat)ySpeedRatio {
    
    Mario* mario = (Mario*)[self getChildByTag:kMarioNode];
    CCNode* map = [self getChildByTag:kTileMapNode];
    
    [mario walking:xSpeedRatio];
    
    float mapWidth = map.contentSize.width;
    float screenWidth = [CCDirector sharedDirector].winSize.width;
    float centerX = screenWidth / 2;
    float mapRightEdgeX = -1 * (mapWidth - screenWidth);
    float mapLeftEdgeX = 0.0;
    
    CCLOG(@"speed = %f, map.pos.x = %f", xSpeedRatio, map.position.x);
    
    if ((map.position.x == mapLeftEdgeX  && xSpeedRatio < 0) ||             //map左端まで表示されていて,左に移動
        (map.position.x == mapLeftEdgeX  && mario.position.x < centerX) ||  //map左端まで表示されていて,マリオが左側にいる
        (map.position.x == mapRightEdgeX && 0 < xSpeedRatio) ||             //map右端まで表示されていて、右に移動
        (map.position.x == mapRightEdgeX && centerX < mario.position.x))    //map右端まで表示されていて、マリオが右側にいる
    {
        //キャラを動かす
        float mx = mario.position.x + (int)(xSpeedRatio * kMarioSpeed);
        
        //画面外にでないように
        if (0 <= mx && mx <= screenWidth) {
            NSLog(@"mx=%f, centerX=%f, mapX=%f", mx, centerX, map.position.x);
            
            if ((map.position.x == mapLeftEdgeX && 0 < xSpeedRatio && centerX < mx) ||
                (map.position.x == mapRightEdgeX && xSpeedRatio < 0 && mx < centerX)) {
                //センターを越えないように
                mario.position = ccp(centerX, mario.position.y);
            } else {
                mario.position = ccp(mx, mario.position.y);
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
        map.position = ccp(newMapX, map.position.y);
        CCLOG(@"map x:%f", map.position.x);
    }
}





@end
