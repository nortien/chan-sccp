# FILE:			AutoMake Makefile for chan-sccp
# COPYRIGHT:		http://chan-sccp.github.io/chan-sccp/ group 2011
# CREATED BY:		Diederik de Groot <ddegroot@sourceforge.net>
# LICENSE: 		This program is free software and may be modified and distributed under the terms of the GNU Public License version 3.
# 			See the LICENSE file at the top of the source tree.
# NOTE:			Process this file with automake to produce a makefile.in script.

include 		$(top_srcdir)/src/Makefile.inc.am

noinst_LTLIBRARIES	= libast123.la
noinst_HEADERS		= ast123.h

# Force-included via libast123_la_CFLAGS below, which automake does not treat as a
# distributed source - list it explicitly so `make dist` keeps it in the tarball.
EXTRA_DIST		= ast123_compat.h

libast123_la_SOURCES	= ast123.c
libast123_la_CFLAGS	= $(AM_CFLAGS) -include $(srcdir)/ast123_compat.h
libast123_la_LDFLAGS	= $(AM_LDFLAGS)
