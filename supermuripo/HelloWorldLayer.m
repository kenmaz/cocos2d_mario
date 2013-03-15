//
//  HelloWorldLayer.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/14.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer {
    ZJoystick *_joystick;
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

static const int TileMapNode = 1;

-(id) init
{
	if( (self=[super init]) ) {
		
        CCTMXTiledMap* tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"mario.tmx"];
        [self addChild:tileMap z:-1 tag:TileMapNode];
        /*
        CGSize winSize = [CCDirector sharedDirector].winSize;
        CCSprite *controlledSprite  = [CCSprite spriteWithFile:@"Joystick_norm.png"];
        controlledSprite.position   = ccp(winSize.width/2, winSize.height/2);
        [self addChild:controlledSprite];
        */
        
        //Joystick
        _joystick	= [ZJoystick joystickNormalSpriteFile:@"JoystickContainer_norm.png" selectedSpriteFile:@"JoystickContainer_trans.png" controllerSpriteFile:@"Joystick_norm.png"];
        _joystick.position	= ccp(_joystick.contentSize.width/2, _joystick.contentSize.height/2);
        _joystick.delegate	= self;				//Joystick Delegate
        //_joystick.controlledObject  = controlledSprite;     //we set our controlled object which the blue circle
        _joystick.speedRatio         = 2.0f;                //we set speed ratio, movement speed of blue circle once controlled to any direction
        _joystick.joystickRadius     = 50.0f;               //Added in v1.2
        [self addChild:_joystick];
	}
	return self;
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

-(void)joystickControlBegan {
    NSLog(@"begin");
}
-(void)joystickControlMoved {
    NSLog(@"move");
}
-(void)joystickControlEnded {
    NSLog(@"end");
}

-(void)joystickControlDidUpdate:(id)joystick toXSpeedRatio:(CGFloat)xSpeedRatio toYSpeedRatio:(CGFloat)ySpeedRatio {
    
}

@end
