//
//  HelloWorldLayer.h
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/14.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "Mario.h"

typedef enum {
    GameSceneLayerTagGame = 1,
    GameSceneLayerTagInput,
} GameSceneLayerTags;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>

@property Mario* mario;
@property CCTMXTiledMap* map;

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene *) scene;
+ (HelloWorldLayer*)sharedInstance;

@end
