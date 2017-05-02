//
//  ios_prefix.h
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

#ifndef ios_prefix_h
#define ios_prefix_h


#import <Availability.h>
#import <TargetConditionals.h>

#define OK 1
#define HAVE_DIRENT_H 1
#define HAVE_STDARG_H 1
#define HAVE_OPENDIR 1
#define MACOS_X_UNIX 1
#define ALWAYS_USE_GUI 1
#define FEAT_GUI 1
#define MULTI_BYTE 1
#define FEAT_GUI_SCROLL_WHEEL_FORCE 1
#define FEAT_GUI_IOS 1
#define FEAT_BROWSE
#define TARGET_OS_IPHONE 1


int VimMain(int argc, char *argv[]);

#endif /* ios_prefix_h */
