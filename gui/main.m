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

#include <stdio.h>
#include <Cocoa/Cocoa.h>

#include "WKWindow.h"

#define EYETUNES_URL "http://127.0.0.1:2000/"

__dead void usage(void);

int main(int argc, char* argv[])
{
	int ch;
	int height = 0, width = 0, x = 0, y = 0;

	while ((ch = getopt(argc, argv, "h:w:x:y:")) != -1)
		switch (ch) {
		case 'h':
			height = (int)strtol(optarg, (char **)NULL, 10);
			break;
		case 'w':
			width = (int)strtol(optarg, (char **)NULL, 10);
			break;
		case 'x':
			x = (int)strtol(optarg, (char **)NULL, 10);
			break;
		case 'y':
			y = (int)strtol(optarg, (char **)NULL, 10);
			break;
		default:
			usage();
		}

	argc -= optind;
	argv += optind;

	if (height <= 0 || width <= 0 || x < 0 || y < 0)
		usage();

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	WKWindow *WKW = [WKWindow alloc];
	[WKW initWithX:x y:y width:width height:height];
	[WKW loadURL:[NSString stringWithFormat:@"%s", EYETUNES_URL]];

	/* give us a simple icon so we can quit */
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

	[NSApp run];

	[pool release];
	return (0);
}

__dead void
usage(void)
{
	extern char *__progname;

	fprintf(stderr, "usage: %s -x x -y y -w width -h height\n", __progname);
	exit(1);
}
