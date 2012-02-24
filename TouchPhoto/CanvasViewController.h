//
//  CanvasViewController.h
//  TouchPhoto
//
//  Created by Cong Vo @ http://kong.vn on 2/21/12.
//  Copyright (c) 2012 BeeDream Studios. All rights reserved.
//

// Tutorial
// http://kong.vn/2011/09/pan-zoom-multitouch-1/
// http://kong.vn/2011/11/pan-zoom-multitouch-2/

#import <GLKit/GLKit.h>

@interface CanvasViewController : GLKViewController

- (void)panWithVector:(CGPoint)vector;

@end
