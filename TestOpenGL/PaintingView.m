//
//  PaintingView.m
//  TestOpenGL
//
//  Created by phm on 16/1/11.
//  Copyright © 2016年 phm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PaintingView.h"
#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import "fileUtil.h"

typedef struct
{
    int text_id;
    float width;
    float height;
    
} textureinfo_id;

@interface PaintingView()
{
    textureinfo_id brushTexture;     // brush texture
    
}
@end
@implementation PaintingView

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
    }
    return self;
}

-(void)setLayer
{
    CAEAGLLayer* layer = (CAEAGLLayer*)self.layer;
    
    layer.opaque = true;
}

-(void)setContext
{
    EAGLRenderingAPI api =  kEAGLRenderingAPIOpenGLES2;
    
    _context = [[EAGLContext alloc] initWithAPI:api];
    
    if(!_context)
    {
        NSLog(@"init context failed");
        
        exit(1);
    }
    
    if(![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"set current context failed");
        
        exit(1);
    }
}

-(void)setupColorBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
}

-(void)setupDepthBuffer
{
    glGenRenderbuffers(1, &_depthRenderBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

-(void)setFrameBuffer
{
    glGenFramebuffers(1, &_defaultFrameBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFrameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    
    GLuint state = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if(state != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"set framebuffer failed %x",state);
        
        exit(1);
    }
}

-(void)setProgram
{
    
    //创建opengl program
    GLuint program = glCreateProgram();
    _programID=program;
    
    //编译shader
    char* vSrc = readFile(pathForResource("point.vsh"));
    
    const char* vSrc_weakRef = vSrc;
    //编译顶点shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &(vSrc_weakRef), NULL);
    glCompileShader(vertexShader);
    
    GLint logLength;
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0)
    {
        GLchar* log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        printf("vertex Shader compile log :%s",log);
        free(log);
    }
    
    logLength = 0;
    //编译片段shader
    char* fSrc = readFile(pathForResource("point.fsh"));
    const char* fSrc_weakRef = fSrc;
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fSrc_weakRef, NULL);
    glCompileShader(fragmentShader);
    
    glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0)
    {
        GLchar* log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(fragmentShader, logLength, &logLength, log);
        printf("fragment Shader compile log:%s",log);
        free(log);
    }
    
    //将shader 附加到program
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    //链接
    glLinkProgram(program);
    glueValidateProgram(_programID);
    glUseProgram(_programID);
    
    free(vSrc);
    free(fSrc);
}
-(GLint)getAttribLocation:(GLuint)program name:(const char*)name
{
    GLint location = glGetAttribLocation(program, name);
    
    return location;
}

-(GLint)getUniformLocation:(GLuint)program name:(const char*)name
{
    GLint location = glGetUniformLocation(program, name);
    
    return location;
}

-(void)parseUniform:(GLuint)program
{
    GLint maxActiveUnifom;
    glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &maxActiveUnifom);
    if(maxActiveUnifom <= 0) return;
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxLength);
    if(maxLength <= 0) return;
    GLchar* name = (GLchar*)malloc(maxLength);
    
    GLint size;
    GLenum type;
    for(int i = 0;i<maxActiveUnifom;i++)
    {
        glGetActiveUniform(program, i, maxLength, NULL, &size, &type, name);
        name[maxLength] = '\0';
        
        NSString* key = [NSString stringWithUTF8String:name];
        
        GLint location = glGetUniformLocation(program, name);
        
        [_uniformID setObject:[NSNumber numberWithInt:location] forKey:key];
        
    }
}

-(void)createVBO
{
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    // Update projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _backingWidth, 0, _backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
    glUniformMatrix4fv([[_uniformID valueForKey:@"MVP"] intValue], 1, GL_FALSE, MVPMatrix.m);
    
    glUniform1f([[_uniformID valueForKey:@"PointSize"] intValue], brushTexture.width/2);
    
    glUniform4f([[_uniformID valueForKey:@"vColor"] intValue], 1.0,0.0 , 0.5, 1.0);
    
    glUniform1i([[_uniformID valueForKey:@"texture"] intValue], 0);
    //根据渲染的宽高设置视口的大小
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    NSEnumerator * enumeratorKey = [_attribID keyEnumerator];
    
    const GLchar* pos = "vPos";
    
    for(NSObject* object in enumeratorKey)
    {
        NSString* key = (NSString*)object;
        
        GLuint value = (GLuint)[[_attribID valueForKey:key] intValue];
        glBindAttribLocation(_programID,value,pos);
        
    }
    
    glGenBuffers(1, &_vboID);
}

-(textureinfo_id)genTexture:(NSString*)name
{
    CGImageRef image = [UIImage imageNamed:name].CGImage;
    float width = CGImageGetWidth(image);
    float height = CGImageGetHeight(image);
    
    GLubyte* brushdata = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    CGContextRef brushContext =CGBitmapContextCreate(brushdata, width, height, 8, width*4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image);
    CGContextRelease(brushContext);
    
    GLuint text;
    glGenTextures(1,&text);
    glBindTexture(GL_TEXTURE_2D, text);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,GL_UNSIGNED_BYTE , brushdata);
    
    textureinfo_id textinfo;
    textinfo.text_id = text;
    textinfo.width = width;
    textinfo.height = height;
    
    free(brushdata);
    
    return textinfo;
    
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    static GLfloat*		vertexBuffer = NULL;
    static NSUInteger	vertexMax = 64;
    NSUInteger			vertexCount = 0,
    count,
    i;
    
    [EAGLContext setCurrentContext:_context];
    glUseProgram(_programID);
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFrameBuffer);
    
    // Convert locations from Points to Pixels
    CGFloat scale = 1.0;
    start.x *= scale;
    start.y *= scale;
    end.x *= scale;
    end.y *= scale;
    
    // Allocate vertex array buffer
    if(vertexBuffer == NULL)
        vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    
    // Add points to the buffer so there are drawing points every X pixels
    count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / 2), 1);
    for(i = 0; i < count; ++i) {
        if(vertexCount == vertexMax) {
            vertexMax = 2 * vertexMax;
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
        }
        
        vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
        vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
        vertexCount += 1;
    }
    
    // Load data to the Vertex Buffer Object
    glBindBuffer(GL_ARRAY_BUFFER, _vboID);
    glBufferData(GL_ARRAY_BUFFER, vertexCount*2*sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    // Draw
    glDrawArrays(GL_POINTS, 0, (int)vertexCount);
    
    
    // Display the buffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)parseAttrib:(GLuint)program
{
    GLint maxActiveAttrib;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &maxActiveAttrib);
    if(maxActiveAttrib <= 0) return;
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxLength);
    if(maxLength <= 0) return;
    GLchar* name = (GLchar*)malloc(maxLength);
    
    GLint size;
    GLenum type;
    for(int i = 0;i<maxActiveAttrib;i++)
    {
        glGetActiveAttrib(program, i, maxLength, NULL, &size, &type, name);
        name[maxLength] = '\0';
        
        NSString* key = [NSString stringWithUTF8String:name];
        
        GLint location = glGetAttribLocation(program, name);
        
        [_attribID setObject:[NSNumber numberWithInt:location] forKey:key];
    }
}

-(void)layoutSubviews
{
    
    
    if (!_isInit) {
        _isInit = [self initGL];
    }
    else {
        [EAGLContext setCurrentContext:_context];
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
}

-(BOOL)initGL
{
    [self setLayer];
    [self setContext];
    [self setupColorBuffer];
    [self setupDepthBuffer];
    [self setFrameBuffer];
    
    brushTexture = [self genTexture:@"Particle.png"];
    [self setProgram];
    
    _uniformID = [[NSMutableDictionary alloc] init];
    _attribID  = [[NSMutableDictionary alloc] init];
    
    [self parseAttrib:_programID];
    [self parseUniform:_programID];
    
    [self createVBO];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    return true;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    // Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    // For this sample, we do not need a depth buffer. If you do, this is how you can allocate depth buffer backing:
    //    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
    //    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer objectz %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // Update projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _backingWidth, 0, _backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUseProgram(_programID);
    glUniformMatrix4fv([[_uniformID valueForKey:@"MVP"] intValue], 1, GL_FALSE, MVPMatrix.m);
    
    // Update viewport
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    return YES;
}

GLint glueValidateProgram(GLuint program)
{
    GLint logLength, status;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        printf("Failed to validate program %d", program);
    GLenum err = glGetError();
    if (err != GL_NO_ERROR) {
        printf("glError: %04x caught at %s:%u\n", err, __FILE__, __LINE__);
    }
    
    return status;
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _lastPoint = [[touches anyObject] locationInView:self];
    
    _lastPoint = [self convertPointToGL:_lastPoint];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint curPoint = [[touches anyObject] locationInView:self];
    
    curPoint = [self convertPointToGL:curPoint];
    
    [self drawLineFromPoint:_lastPoint to:curPoint];
    
    _lastPoint = curPoint;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint curPoint = [[touches anyObject] locationInView:self];
    
    curPoint = [self convertPointToGL:curPoint];
    
    [self drawLineFromPoint:_lastPoint to:curPoint];
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
}

-(void)drawLineFromPoint:(CGPoint)point1 to:(CGPoint)point2
{
    [self renderLineFromPoint:point1 toPoint:point2];
}

-(CGPoint)convertPointToGL:(CGPoint)point
{
    CGPoint ret = CGPointMake(0, 0);
    
    CGFloat height = self.frame.size.height;
    
    CGFloat glY = height - point.y;
    
    ret = CGPointMake(point.x, glY);
    
    return ret;
}

@end