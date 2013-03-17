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
static const int kDebugNode = 3;

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer {
    ZJoystick *_joystick;
    
    Mario* _mario;
    CCTMXTiledMap* _map;
    
    CCSprite* _debugLastSprite;
    CCLabelTTF* _debugLabel;
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
        _map = [CCTMXTiledMap tiledMapWithTMXFile:@"mario.tmx"];
        [self addChild:_map z:-1 tag:kTileMapNode];

        //マリオ
        _mario = [[Mario alloc] initwithPosition:ccp([CCDirector sharedDirector].winSize.width / 2, kSpriteSize * 4.5)];
        [self addChild:_mario z:100 tag:kMarioNode];
        
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
        
        __block Mario* targetMario = _mario;
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
        
        //debug
        _debugLabel = [[CCLabelTTF alloc] init];
        _debugLabel.fontSize = 20;
        _debugLabel.string = @"";
        _debugLabel.position = ccp(240, 300);
        _debugLabel.tag = kDebugNode;
        [self addChild:_debugLabel];
        
        [self scheduleUpdate];
	}
	return self;
}

- (void)update:(ccTime)delta {
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

#pragma mark - GameKit delegate

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
    [_mario startWalk];
}

//ジョイスティック離した
-(void)joystickControlEnded {
    [_mario startStand];
}

//ジョイスティック操作
-(void)joystickControlDidUpdate:(id)joystick toXSpeedRatio:(CGFloat)xSpeedRatio toYSpeedRatio:(CGFloat)ySpeedRatio {
    [_mario moveToXSpeedRatio:xSpeedRatio toYSpeedRatio:ySpeedRatio withMap:_map];    
}


@end
