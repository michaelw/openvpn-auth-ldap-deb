/*
 * TRConfig.m
 * Generic Configuration Parser
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "TRConfig.h"

@implementation TRConfig

/*!
 * Initialize and return a TRConfig parser.
 * @param fd: A file descriptor open for reading. This file descriptor will be
 * 		mmap()ed, and thus must reference a file.
 */
- (id) initWithFD: (int) fd configDelegate: (id <TRConfigDelegate>) delegate {
	self = [self init];

	if (self) {
		_fd = fd;
		_delegate = delegate;
		_error = NO;
	}

	return self;
}

/*!
 * Parse the configuration file
 * @result true on success, false on failure.
 */
- (BOOL) parseConfig {
	TRConfigLexer *lexer = NULL;
	TRConfigToken *token;
	void *parser;

	/* Initialize our lexer */
	lexer = [[TRConfigLexer alloc] initWithFD: _fd];
	if (lexer == NULL)
		return false;

	/* Initialize the parser */
	parser = TRConfigParseAlloc(malloc);

	/* Scan in tokens and hand them off to the parser */
	while ((token = [lexer scan]) != NULL) {
		TRConfigParse(parser, [token tokenID], token, _delegate);
		/* If we've been asked to stop, do so */
		if (_error)
			break;
	}
	/* Signal EOF and clean up */
	TRConfigParse(parser, 0, NULL, _delegate);
	TRConfigParseFree(parser, free);
	[lexer release];

	/* Did an error occur? */
	if (_error)
		return false;

	return true;
}

/* Re-entrant callback used to signal an error by the parser delegate, called
 * from within the bowels of TRConfigParse() */
- (void) errorStop {
	_error = YES;
}

@end
