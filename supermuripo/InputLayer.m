//
//  InputLayer.m
//  supermuripo
//
//  Created by 松前 健太郎 on 2013/03/18.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "InputLayer.h"
#import "JumpButton.h"
#import "HelloWorldLayer.h"

@implementation InputLayer {
    ZJoystick* _joystick;
    JumpButton* _jumpButton;
}

- (id)init {
    if ((self = [super init])) {
        [self addControls];
        [self scheduleUpdate];
    }
    return self;
}

- (void)addControls {
    //ジョイスティック
    _joystick = [ZJoystick joystickNormalSpriteFile:@"cursor.png" selectedSpriteFile:@"cursor.png" controllerSpriteFile:@"Joystick_norm.png"];
    _joystick.position = ccp(_joystick.contentSize.width/2, _joystick.contentSize.height/2);
    _joystick.delegate = self;
    _joystick.speedRatio = 2.0f;
    _joystick.joystickRadius = 100.0f;
    [self addChild:_joystick];
    
    //ジャンプボタン
    _jumpButton = [JumpButton itemWithNormalImage:@"button.png" selectedImage:@"button.png" target:self selector:@selector(starButtonTapped:)];
    float screenWidth = [CCDirector sharedDirector].winSize.width;
    _jumpButton.position = ccp(screenWidth - _jumpButton.contentSize.width / 2, _jumpButton.contentSize.height / 2);
    CCMenu *buttonBase = [CCMenu menuWithItems:_jumpButton, nil];
    buttonBase.position = CGPointZero;
    [self addChild:buttonBase];
    
}

- (void)update:(ccTime)delta {
    Mario* mario = [HelloWorldLayer sharedInstance].mario;
    
    if (_jumpButton.active) {
        [mario jumpWithButtonTouchHolding:YES];
    } else {
        [mario jumpWithButtonTouchHolding:NO];
    }
}

- (void)starButtonTapped:(id)sender {
    // do nothing
}

#pragma mark - //JoystickDelegate

//ジョイスティック押した
-(void)joystickControlBegan {
    Mario* mario = [HelloWorldLayer sharedInstance].mario;
    [mario startWalk];
}

//ジョイスティック離した
-(void)joystickControlEnded {
    Mario* mario = [HelloWorldLayer sharedInstance].mario;
    [mario startStand];
}

//ジョイスティック操作
-(void)joystickControlDidUpdate:(id)joystick toXSpeedRatio:(CGFloat)xSpeedRatio toYSpeedRatio:(CGFloat)ySpeedRatio {
    Mario* mario = [HelloWorldLayer sharedInstance].mario;
    [mario moveToXSpeedRatio:xSpeedRatio toYSpeedRatio:ySpeedRatio];
}



@end
