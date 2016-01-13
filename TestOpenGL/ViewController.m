//
//  ViewController.m
//  TestOpenGL
//
//  Created by phm on 16/1/11.
//  Copyright © 2016年 phm. All rights reserved.
//

#import "ViewController.h"
#import "PaintingView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGRect size = [[UIScreen mainScreen] bounds];
    PaintingView* view = [[PaintingView alloc] initWithFrame:size];
    self.view = view;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
