# FILE:			AutoMake Makefile for chan-sccp
# COPYRIGHT:		http://chan-sccp.github.io/chan-sccp/ group 2011
# CREATED BY:		Diederik de Groot <ddegroot@sourceforge.net>
# LICENSE: 		This program is free software and may be modified and distributed under the terms of the GNU Public License version 3.
# 			See the LICENSE file at the top of the source tree.
# NOTE:			Process this file with automake to produce a makefile.in script.

include 		$(top_srcdir)/src/Makefile.inc.am

noinst_LTLIBRARIES	= libast121.la
noinst_HEADERS		= ast121.h

# Force-included via libast121_la_CFLAGS below, which automake does not treat as a
# distributed source - list it explicitly so `make dist` keeps it in the tarball.
EXTRA_DIST		= ast121_compat.h

libast121_la_SOURCES	= ast121.c
libast121_la_CFLAGS	= $(AM_CFLAGS) -include $(srcdir)/ast121_compat.h
libast121_la_LDFLAGS	= $(AM_LDFLAGS)
