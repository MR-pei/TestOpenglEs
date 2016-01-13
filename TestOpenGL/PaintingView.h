//
//  PaintingView.h
//  TestOpenGL
//
//  Created by phm on 16/1/11.
//  Copyright © 2016年 phm. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PaintingView : UIView
{
    NSMutableDictionary* _uniformID;
    NSMutableDictionary* _attribID;
    
    GLuint _programID;
    GLuint _defaultFrameBuffer;
    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    
    EAGLContext* _context;
    
    
    CGPoint _lastPoint;
    
    GLint _backingWidth;
    GLint _backingHeight;
    
    GLuint _vboID;
    
    BOOL _isInit;
}

-(void)setLayer;
-(void)setContext;
-(void)setupColorBuffer;
-(void)setupDepthBuffer;
-(void)setFrameBuffer;
-(void)drawLineFromPoint:(CGPoint)point1  to:(CGPoint)point2;

-(CGPoint)convertPointToGL:(CGPoint)point;

@end