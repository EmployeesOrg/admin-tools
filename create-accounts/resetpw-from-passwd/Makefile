
PROG=	resetpw
NOMAN=  "yes"
SRCS=	local_passwd.c resetpw.c pw_copy.c pw_scan.c pw_util.c
CFLAGS+=-Wall

DPADD=	${LIBCRYPT} ${LIBUTIL}
LDADD=	-lcrypt -lutil


CFLAGS+= -DCRYPT  -I. -I${.CURDIR} \
	 -DLOGGING

BINMODE=4555

.include <bsd.prog.mk>
