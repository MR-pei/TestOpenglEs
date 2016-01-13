//
//  point.vsh
//  TestOpenGL
//
//  Created by phm on 16/1/11.
//  Copyright © 2016年 phm. All rights reserved.
//

attribute vec4 vPos;

uniform mat4 MVP;

uniform vec4 vColor;

uniform float PointSize;

varying lowp vec4 color;

void main()
{
    gl_Position = MVP*vPos;
    
    color = vColor;
    
    gl_PointSize = PointSize;
}
