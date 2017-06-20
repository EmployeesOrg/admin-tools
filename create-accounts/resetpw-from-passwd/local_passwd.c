/*-
 * Copyright (c) 1990, 1993, 1994
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $FreeBSD: src/usr.bin/passwd/local_passwd.c,v 1.24.2.3 2002/03/24 09:00:11 cjc Exp $
 */

#ifndef lint
static const char sccsid[] = "@(#)local_passwd.c	8.3 (Berkeley) 4/2/94";
#endif /* not lint */

#include <sys/types.h>
#include <sys/time.h>

#include <ctype.h>
#include <err.h>
#include <errno.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <pw_copy.h>
#include <pw_util.h>

#ifdef LOGGING
#include <syslog.h>
#endif

#ifdef LOGIN_CAP
#ifdef AUTH_NONE /* multiple defs :-( */
#undef AUTH_NONE
#endif
#include <login_cap.h>
#endif

#include "extern.h"

static uid_t uid;
int randinit;

char   *tempname;

static unsigned char itoa64[] =		/* 0 ... 63 => ascii - 64 */
	"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

void
to64(s, v, n)
	char *s;
	long v;
	int n;
{
	while (--n >= 0) {
		*s++ = itoa64[v&0x3f];
		v >>= 6;
	}
}

char *
getnewpasswd(pw)
	struct passwd *pw;
{
	char buf[_PASSWORD_LEN+1], salt[32];
	struct timeval tv;
	char *cp;
	int cc;

	if ((cc = read(0, buf, _PASSWORD_LEN)) < 0) {
		perror("read");
		exit(1);
	}
	/* NUL terminate */
	buf[cc] = '\0';

        /* Kill any CR/LF that might have sneaked in */
	if ((cp = strchr(buf, '\r')) != NULL)
		*cp = '\0';
	if ((cp = strchr(buf, '\n')) != NULL)
		*cp = '\0';

	/* grab a random printable character that isn't a colon */
	if (!randinit) {
		randinit = 1;
		srandomdev();
	}
#ifdef NEWSALT
	salt[0] = _PASSWORD_EFMT1;
	to64(&salt[1], (long)(29 * 25), 4);
	to64(&salt[5], random(), 4);
	salt[9] = '\0';
#else
	/* Make a good size salt for algoritms that can use it. */
	gettimeofday(&tv,0);
	(void)crypt_set_format("md5");
	/* Salt suitable for anything */
	to64(&salt[0], random(), 3);
	to64(&salt[3], tv.tv_usec, 3);
	to64(&salt[6], tv.tv_sec, 2);
	to64(&salt[8], random(), 5);
	to64(&salt[13], random(), 5);
	to64(&salt[17], random(), 5);
	to64(&salt[22], random(), 5);
	salt[27] = '\0';
#endif
	return (crypt(buf, salt));
}

int
local_passwd(uname)
	char *uname;
{
	struct passwd *pw;
	int pfd, tfd;

	if (!(pw = getpwnam(uname)))
		errx(1, "unknown user %s", uname);

	uid = getuid();
	if (uid && uid != pw->pw_uid)
		errx(1, "%s", strerror(EACCES));

	pw_init();

	/*
	 * Get the new password.  Reset passwd change time to zero by
	 * default. If the user has a valid login class (or the default
	 * fallback exists), then the next password change date is set
	 * by getnewpasswd() according to the "passwordtime" capability
	 * if one has been specified.
	 */
	pw->pw_change = 0;
	pw->pw_passwd = getnewpasswd(pw);

	pfd = pw_lock();
	tfd = pw_tmp();
	pw_copy(pfd, tfd, pw, NULL);

	if (!pw_mkdb(uname))
		pw_error((char *)NULL, 0, 1);
#ifdef LOGGING
	syslog(LOG_DEBUG, "user %s changed their local password\n", uname);
#endif
	return (0);
}
