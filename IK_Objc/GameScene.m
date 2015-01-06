//
//  GameScene.m
//  IK_Objc
//
//  Created by yuchen liu on 15/1/4.
//  Copyright (c) 2015年 rain. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"

CGFloat const upperArmAngleDeg = -10 * M_PI / 180;
CGFloat const lowerArmAngleDeg = 130 * M_PI / 180;

CGFloat const upperLegAngleDeg = 22 * M_PI / 180;
CGFloat const lowerLegAngleDeg = -30 * M_PI / 180;


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
    
    SKNode *_upperLeg;
    SKNode *_lowerLeg;
    SKNode *_foot;
    
    BOOL _rightPunch;
    BOOL _firstTouch;
    
    NSTimeInterval _lastSpawnTimeInterval;
    NSTimeInterval _lastUpdateTimeInterval;
    
    int _score;
    int _life;
    
    SKLabelNode *_scoreLabel;
    SKLabelNode *_lifeLabel;
}

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    _score = 0;
    _life = 3;
    
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", _score];
    _scoreLabel.fontSize = 20;
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    _scoreLabel.position = CGPointMake(10, self.size.height - 10);
    [self addChild:_scoreLabel];
    
    _lifeLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _lifeLabel.text = [NSString stringWithFormat:@"Lives: %d", _life];
    _lifeLabel.fontSize = 20;
    _lifeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    _lifeLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    _lifeLabel.position = CGPointMake(self.size.width - 10, self.size.height - 10);
    [self addChild:_lifeLabel];
    
    
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
    
    _upperLeg = [_lowerTorso childNodeWithName:@"leg_upper_back"];
    _lowerLeg = [_upperLeg childNodeWithName:@"leg_lower_back"];
    _foot = [_lowerLeg childNodeWithName:@"foot_back"];
    
    _upperLeg.reachConstraints = [[SKReachConstraints alloc] initWithLowerAngleLimit:-45.0 upperAngleLimit:160.0];
    _lowerLeg.reachConstraints = [[SKReachConstraints alloc] initWithLowerAngleLimit:-90.0 upperAngleLimit:0.0];
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
    
    SKAction *hitAction = [SKAction runBlock:^{
        if (_life > 0) {
            _life--;
        }
        
        _lifeLabel.text = [NSString stringWithFormat:@"Lives: %d", _life];
        
        SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.05], [SKAction fadeInWithDuration:0.05]]];
        
        SKAction *checkGameOverAction = [SKAction runBlock:^{
            if (_life <= 0) {
                
                SKTransition *transtion = [SKTransition fadeWithDuration:1.0];
                
                //check win or fail
                BOOL won;
                
                if (_score >= 5) {
                    won = YES;
                }else{
                    won = NO;
                }
                
                GameOverScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.view.bounds.size won:won];
                
                [self.view presentScene:gameOverScene transition:transtion];
            }
        }];
        
        [_lowerTorso runAction:[SKAction sequence:@[blink, blink, checkGameOverAction]]];
    }];
    
    [shuriken runAction:[SKAction sequence:@[actionMove, hitAction,actionMoveDone]]];
    
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
                        [self runAction:[SKAction playSoundFileNamed:@"hit.mp3" waitForCompletion:NO]];
                        
                        //show spark
                        SKSpriteNode *spark = [SKSpriteNode spriteNodeWithImageNamed:@"spark"];
                        spark.position = node.position;
                        spark.zPosition = 50;
                        [self addChild:spark];
                        
                        SKAction *fadeAndScale = [SKAction group:@[[SKAction fadeOutWithDuration:0.2], [SKAction scaleTo:0.1 duration:0.2]]];
                        SKAction *cleanUp = [SKAction removeFromParent];
                        
                        [spark runAction:[SKAction sequence:@[fadeAndScale, cleanUp]]];
                        
                        //update score
                        _score++;
                        _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", _score];
                        
                        [node removeFromParent];
                    }
                    else{
                        [self runAction:[SKAction playSoundFileNamed:@"miss.mp3" waitForCompletion:NO]];
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

-(void)kickAtLocation:(CGPoint)location{
    SKAction *kick = [SKAction reachTo:location rootNode:_upperLeg duration:0.1];
    
    SKAction *restore = [SKAction runBlock:^{
        [_upperLeg runAction:[SKAction rotateToAngle:upperLegAngleDeg duration:0.1]];
        [_lowerLeg runAction:[SKAction rotateToAngle:lowerLegAngleDeg duration:0.1]];
    }];
    
    SKAction *checkIntersection = [self intersectionCheckActionForNode:_foot];
    
    [_foot runAction:[SKAction sequence:@[kick,checkIntersection,restore]]];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
    
        _lowerTorso.xScale = location.x < CGRectGetMidX(self.frame)? fabs(_lowerTorso.xScale) * -1 : fabs(_lowerTorso.xScale);
        
        BOOL lower = location.y < _lowerTorso.position.y;
        
        if (lower) {
            [self kickAtLocation:location];
        }else{
            [self punchAtLocation:location];
        }
        
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
