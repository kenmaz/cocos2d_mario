//
//  HelloWorldLayer.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/14.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "JumpButton.h"
#import "InputLayer.h"

static const int kTileMapNode = 1;
static const int kMarioNode = 2;
static const int kDebugNode = 3;

#pragma mark - HelloWorldLayer

static HelloWorldLayer* instance;

// HelloWorldLayer implementation
@implementation HelloWorldLayer {
    CCSprite* _debugLastSprite;
    CCLabelTTF* _debugLabel;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
    
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[scene addChild:layer z:0 tag:GameSceneLayerTagGame];
    
    InputLayer* inputLayer = [InputLayer node];
    [scene addChild:inputLayer z:1 tag:GameSceneLayerTagInput];
	
	return scene;
}

+ (HelloWorldLayer*)sharedInstance {
    return instance;
}

- (id)init
{
	if( (self=[super init]) ) {
		instance = self;
        
        //背景タイル
        self.map = [CCTMXTiledMap tiledMapWithTMXFile:@"mario.tmx"];
        [self addChild:self.map z:-1 tag:kTileMapNode];

        //マリオ
        self.mario = [[Mario alloc] initWithPosition:ccp([CCDirector sharedDirector].winSize.width / 2, kSpriteSize * 4.5)];
        [self addChild:self.mario z:100 tag:kMarioNode];
        
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
    _debugLabel.string = [NSString stringWithFormat:@"mario=%@", NSStringFromCGPoint(self.mario.position)];
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


@end
