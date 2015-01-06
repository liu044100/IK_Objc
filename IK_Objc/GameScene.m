//
//  GameScene.m
//  IK_Objc
//
//  Created by yuchen liu on 15/1/4.
//  Copyright (c) 2015年 rain. All rights reserved.
//

#import "GameScene.h"

CGFloat const upperArmAngleDeg = -10 * M_PI / 180;
CGFloat const lowerArmAngleDeg = 130 * M_PI / 180;

@implementation GameScene{
    SKNode *_shadow;
    SKNode *_lowerTorso;
    SKNode *_upperTorso;
    
    SKNode *_upperArmFront;
    SKNode *_lowerArmFront;
    SKNode *_fistFront;
    
    SKNode *_upperArmBack;
    SKNode *_lowerArmBack;
    SKNode *_fistBack;
    
    SKNode *_head;
    SKNode *_targetNode;
    
    BOOL _rightPunch;
    BOOL _firstTouch;
    
    NSTimeInterval _lastSpawnTimeInterval;
    NSTimeInterval _lastUpdateTimeInterval;
}

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    _lowerTorso = [self childNodeWithName:@"torso_lower"];
    _lowerTorso.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 30);
    
    _shadow = [self childNodeWithName:@"shadow"];
    _shadow.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 100);
    
    _upperTorso = [_lowerTorso childNodeWithName:@"torso_upper"];
    
    _upperArmFront = [_upperTorso childNodeWithName:@"arm_upper_front"];
    _lowerArmFront = [_upperArmFront childNodeWithName:@"arm_lower_front"];
    _fistFront = [_lowerArmFront childNodeWithName:@"fist_front"];
    
    _upperArmBack = [_upperTorso childNodeWithName:@"arm_upper_back"];
    _lowerArmBack = [_upperArmBack childNodeWithName:@"arm_lower_back"];
    _fistBack = [_lowerArmBack childNodeWithName:@"fist_back"];
    
    _head = [_upperTorso childNodeWithName:@"head"];
    _targetNode = [SKNode node];
    
    SKConstraint *orientToNodeConstraint = [SKConstraint orientToNode:_targetNode offset:[SKRange rangeWithConstantValue:0.0]];
    
    SKConstraint *rotateConstraint = [SKConstraint zRotation:[SKRange rangeWithLowerLimit:-50.0 upperLimit:80.0]];
    
    orientToNodeConstraint.enabled = NO;
    rotateConstraint.enabled = NO;
    
    _head.constraints = @[orientToNodeConstraint, rotateConstraint];
    
}

-(void)addShuriken{
    SKSpriteNode *shuriken = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    
    int minY = _lowerTorso.position.y - CGRectGetHeight(self.frame)/5 + shuriken.size.height/2;
    int maxY = _lowerTorso.position.y + CGRectGetHeight(self.frame)/2 - shuriken.size.height/2;
    int rangeY = maxY - minY;

    int actualY = arc4random() % rangeY + minY;
    int left = arc4random() % 2;
    int actualX = (left == 0)? -shuriken.size.width/2 : self.size.width + shuriken.size.width/2;
    
    shuriken.position = CGPointMake(actualX, actualY);
    shuriken.name = @"shuriken";
    shuriken.zPosition = 1;
    [self addChild:shuriken];
    
    int minDuration = 2;
    int maxDuration = 4;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(self.size.width/2, actualY) duration:actualDuration];
    
    SKAction *actionMoveDone = [SKAction removeFromParent];
    
    [shuriken runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
    CGFloat angle = (left == 0)? -M_PI_2 : M_PI_2;
    
    SKAction *rotation = [SKAction repeatActionForever:[SKAction rotateByAngle:angle duration:0.2]];
    [shuriken runAction:rotation];
}

-(SKAction*)intersectionCheckActionForNode:(SKNode*)effectorNode{
    SKAction *checkIntersection = [SKAction runBlock:^{
        
        for (id object in self.children) {
            if ([object isKindOfClass:[SKSpriteNode class]]) {
                SKSpriteNode *node = object;
                if ([node.name isEqualToString:@"shuriken"]) {
                    if ([node intersectsNode:effectorNode]) {
                        //sound
                        [self runAction:[SKAction playSoundFileNamed:@"hit.mp3" waitForCompletion:nil]];
                        
                        //show spark
                        SKSpriteNode *spark = [SKSpriteNode spriteNodeWithImageNamed:@"spark"];
                        spark.position = node.position;
                        spark.zPosition = 50;
                        [self addChild:spark];
                        
                        SKAction *fadeAndScale = [SKAction group:@[[SKAction fadeOutWithDuration:0.2], [SKAction scaleTo:0.1 duration:0.2]]];
                        SKAction *cleanUp = [SKAction removeFromParent];
                        
                        [spark runAction:[SKAction sequence:@[fadeAndScale, cleanUp]]];
                        
                        [node removeFromParent];
                    }
                    else{
                        [self runAction:[SKAction playSoundFileNamed:@"miss.mp3" waitForCompletion:nil]];
                    }
                }
            }
        }

    }];
    
    return checkIntersection;
}

-(void)punchAtLocation:(CGPoint)location upperArmNode:(SKNode*)upperArmNode lowerArmNode:(SKNode*)lowerArmNode fistNode:(SKNode*)fistNode{

    SKAction *punch = [SKAction reachTo:location rootNode:upperArmNode duration:0.1];
    
    SKAction *restore = [SKAction runBlock:^{
        [upperArmNode runAction:[SKAction rotateToAngle:upperArmAngleDeg duration:0.1]];
        [lowerArmNode runAction:[SKAction rotateToAngle:lowerArmAngleDeg duration:0.1]];
    }];
    
    SKAction *checkIntersection = [self intersectionCheckActionForNode:fistNode];
    
    [fistNode runAction:[SKAction sequence:@[punch,checkIntersection,restore]]];
}

-(void)punchAtLocation:(CGPoint)location{
    if (_rightPunch) {
        [self punchAtLocation:location upperArmNode:_upperArmFront lowerArmNode:_lowerArmFront fistNode:_fistFront];
    }else{
        [self punchAtLocation:location upperArmNode:_upperArmBack lowerArmNode:_lowerArmBack fistNode:_fistBack];
    }
    
    _rightPunch = !_rightPunch;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
    
        _lowerTorso.xScale = location.x < CGRectGetMidX(self.frame)? fabs(_lowerTorso.xScale) * -1 : fabs(_lowerTorso.xScale);
        
        [self punchAtLocation:location];
        
        _targetNode.position = location;
    }
    
    if (!_firstTouch) {
        for (SKConstraint *headConstraint in _head.constraints) {
            headConstraint.enabled = YES;
        }
        
        _firstTouch = YES;
    }
}

-(void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast{
    _lastSpawnTimeInterval += timeSinceLast;
    
    if (_lastSpawnTimeInterval > 0.75) {
        _lastSpawnTimeInterval = 0;
        [self addShuriken];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    CFTimeInterval timeSinceLast = currentTime - _lastUpdateTimeInterval;
    
    _lastUpdateTimeInterval = currentTime;
    
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0/60.0;
        _lastUpdateTimeInterval = timeSinceLast;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    
}

@end
