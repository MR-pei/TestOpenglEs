//
//  point.fsh
//  TestOpenGL
//
//  Created by phm on 16/1/11.
//  Copyright © 2016年 phm. All rights reserved.
//

varying lowp vec4 color;

uniform sampler2D texture;

void main()
{
    gl_FragColor = color*texture2D(texture, gl_PointCoord);
}
