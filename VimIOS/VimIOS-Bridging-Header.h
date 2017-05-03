//
//  VimIOS-Bridging-Header.h
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

#ifndef VimIOS_Bridging_Header_h
#define VimIOS_Bridging_Header_h



//#import "vim.h"
//#import "gui.h"
#import <Foundation/Foundation.h>


int const keyCAR;
int const keyBS;
int const keyESC;
int const keyTAB;
int const keyF1;
int const keyUP;
int const keyDOWN;
int const keyLEFT;
int const keyRIGHT;
int const mouseLEFT;
int const mouseDRAG;
int const mouseRELEASE;

//int VimMain(int argc, char *argv[]);
void vimHelper(int argc, NSString *file);
void gui_resize_shell(int pixel_width, int pixel_height);
void gui_update_cursor(int force, int clear_selection);
void gui_undraw_cursor();
void gui_send_mouse_event(int button,int x,int y, int repeated_click, unsigned int modifiers);

int vim_setenv(const unsigned char *name, const unsigned char *value);
int do_cmdline_cmd(const unsigned char *cmd);
int State;
CGFloat gui_fill_x(int col);
CGFloat gui_fill_y(int row);
CGFloat gui_text_x(int row);
CGFloat gui_text_y(int row);

void add_to_input_buf(const unsigned char  *s, int len);
int getCTRLKeyCode(NSString * s);




#endif /* VimIOS_Bridging_Header_h */
