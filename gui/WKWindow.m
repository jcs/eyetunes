/*
 * eyetunesgui
 * Copyright (c) 2011, 2013 joshua stein <jcs@jcs.org>
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WKWindow.h"
#import <Cocoa/Cocoa.h>

@implementation WKWindow

- (id)initWithX:(int)x y:(int)y width:(int)width height:(int)height
{
	screen = [NSScreen mainScreen];
	screen_frame = [screen visibleFrame];

	/* convert normal geometry to cocoa 0,0-is-bottom-left */
	y += height;

	NSRect coords = NSMakeRect((float)x, (float)y, (float)width,
		(float)height);
	self = [[super initWithContentRect:coords
				styleMask:nil
				backing:NSBackingStoreBuffered
				defer:NO
				screen:screen] autorelease];
	[self setBackgroundColor:[NSColor redColor]];
	[self setOpaque:NO];

	currentURL = [[NSURL alloc] init];

	/* XXX: not sure why this 120 is needed */
	NSRect bframe = NSMakeRect(0, 0, (float)width, (float)height - 120);
	browser = [[WebView alloc] initWithFrame:bframe
				frameName:nil
				groupName:nil];
	[browser setGroupName:@"eyetunes"];
	[browser setUIDelegate:self];
	[browser setResourceLoadDelegate:self];
	[browser setFrameLoadDelegate:self];
	wframe = [browser mainFrame];
	[self.contentView addSubview:browser];

	[self makeFirstResponder:browser];
	[self makeKeyAndOrderFront:self];

	/* add a simple menu to refresh and quit */
	NSMenu *menubar = [[NSMenu new] autorelease];
	NSMenuItem *appMenuItem = [[NSMenuItem new] autorelease];
	[menubar addItem:appMenuItem];
	[NSApp setMainMenu:menubar];

	NSMenu *appMenu = [[NSMenu new] autorelease];
	NSMenuItem *refresher = [[[NSMenuItem alloc] initWithTitle:@"Refresh"
		action:@selector(refresh:) keyEquivalent:@"r"] autorelease];
	[refresher setTarget:self];
	[refresher setEnabled:YES];
	[appMenu addItem:refresher];

	[appMenu addItem:[[[NSMenuItem alloc] initWithTitle:@"Quit"
		action:@selector(terminate:) keyEquivalent:@"q"] autorelease]];

	[appMenuItem setSubmenu:appMenu];

	return self;
}

- (void)refresh:(id)sender
{
	[wframe loadRequest:[NSURLRequest requestWithURL:currentURL]];
}

- (void)loadURL:(NSString *)url
{
	currentURL = [NSURL URLWithString:url];

	if ([[currentURL scheme] length] == 0)
		currentURL = [NSURL URLWithString:[NSString
			stringWithFormat:@"http://%@", url]];

	[wframe loadRequest:[NSURLRequest requestWithURL:currentURL]];
}

@end
