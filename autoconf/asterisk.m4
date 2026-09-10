dnl FILE: asterisk.m4
dnl COPYRIGHT: http://chan-sccp.github.io/chan-sccp/ group 2009
dnl CREATED BY: Created by Diederik de Groot
dnl LICENSE: This program is free software and may be modified and distributed under the terms of the GNU Public License version 3.
dnl          See the LICENSE file at the top of the source tree.

dnl How the asterisk version is established. First source that yields a number wins:
dnl
dnl   1. --with-asterisk-version=major.minor   the manual override; never needed, kept for
dnl                                            builds against headers that have no other marker
dnl   2. PACKAGE_VERSION in asterisk/autoconfig.h
dnl                                            asterisk's own configure.ac writes its major there
dnl                                            ("18", "20".."23") - but only since 18.x; every
dnl                                            release tarball of 11-17 and 19 says "trunk"
dnl                                            (checked against the tags on github, 2026-09-10)
dnl   3. AMI_VERSION in asterisk/manager.h     for those "trunk" trees: the AMI major is bumped with
dnl                                            every asterisk major and has been asterisk_major - 11
dnl                                            from 13 (2.x) through 23 (12.0.0); 12 shares the 2.x
dnl                                            major with 13 and is told apart by format_cache.h,
dnl                                            which 13 introduced. Gives the major only
dnl   4. `asterisk -V` of the binary living in the same prefix as the headers
dnl                                            adds the exact minor, and only when its major agrees
dnl                                            with 3. - the header search may point at the system
dnl                                            sbin, whose asterisk need not be the one the headers
dnl                                            belong to
dnl   5. header fingerprints                   the pre-existing chain, now only for AMI 1.x (<= 11)
dnl
dnl asterisk/version.h with its ASTERISK_VERSION macro - what this used to read - has been a hard
dnl #error ("use asterisk/ast_version.h") since 13 already, and ast_version.h only offers functions,
dnl so nothing older than 18 carries a compile-time version string any more.

dnl Parse ${ast_ver_str} into ast_ver_major / ast_ver_minor / ast_ver_patch (minor and patch
dnl default to 0, major stays empty when the string carries no version at all, e.g. "trunk").
dnl Accepts the forms seen in the wild: 23, 13.38.3, 16.28.0~dfsg, GIT-13-abcdef, certified/18.9-cert1,
dnl SVN-branch-1.8-r123456; "GIT-master-abcdef" and "trunk" deliberately yield nothing.
AC_DEFUN([AST_VERSION_PARSE], [
	ast_ver_str=`echo "${ast_ver_str}" | sed -e 's/^"//' -e 's/"$//' -e 's/^Asterisk //' -e 's/^SVN-branch-//' -e 's/^SVN-trunk-//' -e 's/^GIT-//' -e 's/^certified\///'`
	ast_ver_major=`echo "${ast_ver_str}" | sed -n 's/^\([[0-9]][[0-9]]*\).*/\1/p'`
	ast_ver_minor=`echo "${ast_ver_str}" | sed -n 's/^[[0-9]][[0-9]]*\.\([[0-9]][[0-9]]*\).*/\1/p'`
	ast_ver_patch=`echo "${ast_ver_str}" | sed -n 's/^[[0-9]][[0-9]]*\.[[0-9]][[0-9]]*\.\([[0-9]][[0-9]]*\).*/\1/p'`
	if test -n "${ast_ver_major}"; then
		dnl expr strips leading zeros, which printf %d would otherwise read as octal
		ast_ver_major=`expr "${ast_ver_major}" + 0`
		ast_ver_minor=`expr "${ast_ver_minor:-0}" + 0`
		ast_ver_patch=`expr "${ast_ver_patch:-0}" + 0`
	fi
])

dnl Turn ast_ver_major/minor/patch into every version define and substitution the tree relies on.
dnl One place for all five sources, so they cannot drift apart:
dnl   asterisk >= 10 : ASTERISK_VERSION_NUMBER = 1<major><minor%02d>   (13.38 -> 11338, 23.4 -> 12304)
dnl                    ASTERISK_VERSION_GROUP  = 1<major>              (113, 123)
dnl   asterisk 1.x   : ASTERISK_VERSION_NUMBER = 1<minor%02d><patch%02d> (1.6.2 -> 10602)
dnl                    ASTERISK_VERSION_GROUP  = 1<minor%02d>          (106, 108)
dnl ASTERISK_REPOS_LOCATION is expected to be set by the caller beforehand.
AC_DEFUN([AST_VERSION_SET], [
	if test "${ast_ver_major}" = "1"; then
		ASTERISK_VER_GROUP=`printf "1%02d" ${ast_ver_minor}`
		ASTERISK_VERSION_NUMBER=`printf "1%02d%02d" ${ast_ver_minor} ${ast_ver_patch}`
	else
		ASTERISK_VER_GROUP="1${ast_ver_major}"
		ASTERISK_VERSION_NUMBER=`printf "1%d%02d" ${ast_ver_major} ${ast_ver_minor}`
	fi
	ASTERISK_REPOS_LOCATION="${ASTERISK_REPOS_LOCATION:-TGZ}"

	case "${ASTERISK_VER_GROUP}" in
		102)
			REALTIME_USEABLE=0
			AC_DEFINE([ASTERISK_CONF_1_2], [1], [Defined ASTERISK_CONF_1_2]);;
		104) AC_DEFINE([ASTERISK_CONF_1_4], [1], [Defined ASTERISK_CONF_1_4]);;
		106) AC_DEFINE([ASTERISK_CONF_1_6], [1], [Defined ASTERISK_CONF_1_6]);;
		108) AC_DEFINE([ASTERISK_CONF_1_8], [1], [Defined ASTERISK_CONF_1_8]);;
		110) AC_DEFINE([ASTERISK_CONF_1_10], [1], [Defined ASTERISK_CONF_1_10]);;
		111) AC_DEFINE([ASTERISK_CONF_1_11], [1], [Defined ASTERISK_CONF_1_11]);;
		112) AC_DEFINE([ASTERISK_CONF_1_12], [1], [Defined ASTERISK_CONF_1_12]);;
		113) AC_DEFINE([ASTERISK_CONF_1_13], [1], [Defined ASTERISK_CONF_1_13]);;
		114) AC_DEFINE([ASTERISK_CONF_1_14], [1], [Defined ASTERISK_CONF_1_14]);;
		115) AC_DEFINE([ASTERISK_CONF_1_15], [1], [Defined ASTERISK_CONF_1_15]);;
		116) AC_DEFINE([ASTERISK_CONF_1_16], [1], [Defined ASTERISK_CONF_1_16]);;
		117) AC_DEFINE([ASTERISK_CONF_1_17], [1], [Defined ASTERISK_CONF_1_17]);;
		118) AC_DEFINE([ASTERISK_CONF_1_18], [1], [Defined ASTERISK_CONF_1_18]);;
		119) AC_DEFINE([ASTERISK_CONF_1_19], [1], [Defined ASTERISK_CONF_1_19]);;
		120) AC_DEFINE([ASTERISK_CONF_1_20], [1], [Defined ASTERISK_CONF_1_20]);;
		121) AC_DEFINE([ASTERISK_CONF_1_21], [1], [Defined ASTERISK_CONF_1_21]);;
		122) AC_DEFINE([ASTERISK_CONF_1_22], [1], [Defined ASTERISK_CONF_1_22]);;
		123) AC_DEFINE([ASTERISK_CONF_1_23], [1], [Defined ASTERISK_CONF_1_23]);;
		*)
			AC_DEFINE([ASTERISK_CONF], [0], [NOT Defined ASTERISK_CONF !!])
			ASTERISK_INCOMPATIBLE=yes;;
	esac
	AC_DEFINE_UNQUOTED([ASTERISK_VERSION_NUMBER], ${ASTERISK_VERSION_NUMBER}, [ASTERISK Version Number])
	AC_DEFINE_UNQUOTED([ASTERISK_VERSION_GROUP], ${ASTERISK_VER_GROUP}, [ASTERISK Version Group])
	AC_DEFINE_UNQUOTED([ASTERISK_REPOS_LOCATION], ${ASTERISK_REPOS_LOCATION},[ASTERISK Source Location])
	AC_SUBST([ASTERISK_VERSION_NUMBER])
	AC_SUBST([ASTERISK_VER_GROUP])
	AC_SUBST([ASTERISK_REPOS_LOCATION])
	version_found=1
])

dnl The supported window, applied to every auto-detected version (the manual override keeps
dnl its old behaviour of only warning at the end of configure, see ASTERISK_INCOMPATIBLE).
AC_DEFUN([AST_VERSION_CHECK_BOUNDS], [
	if test ${ASTERISK_VER_GROUP} -lt ${MIN_ASTERISK_VERSION}; then
		echo ""
		CONFIGURE_PART([Asterisk Version ${ast_ver_str} Not Supported])
		echo ""
		echo "This version of chan-sccp-b only has support for Asterisk 1.6.x and above."
		echo ""
		echo "Please install a higher version of asterisk"
		echo ""
		echo ""
		exit 255
	fi
	if test ${ASTERISK_VER_GROUP} -gt ${MAX_ASTERISK_VERSION}; then
		echo ""
		CONFIGURE_PART([Asterisk Version ${ast_ver_str} Not Supported])
		echo ""
		echo "This version of chan-sccp-b has no support for Asterisk ${ast_ver_major} yet."
		echo ""
		echo "Please install a lower version of asterisk"
		echo ""
		echo ""
		exit 255
	fi
])

dnl Source 3: AMI_VERSION in manager.h, read straight from the file the header search found
dnl (it needs no compiler: the define is a plain quoted string on its own line in every version).
dnl Only works out the asterisk major, into ast_ami_asterisk_major; whether the binary or this
dnl fingerprint gets to set the version is decided by the caller.
AC_DEFUN([AST_VERSION_AMI_MAJOR], [
	AC_MSG_CHECKING([AMI_VERSION in asterisk/manager.h, as a fingerprint of the asterisk major])
	ast_manager_h=""
	for ast_inc_dir in "${PBX_INCLUDE}" "${PBX_INCLUDE}/asterisk" "${checkdir:+${checkdir}/include/asterisk}"; do
		if test -z "${ast_manager_h}" && test -n "${ast_inc_dir}" && test -f "${ast_inc_dir}/manager.h"; then
			ast_manager_h="${ast_inc_dir}/manager.h"
		fi
	done
	ast_ami_major=""
	if test -n "${ast_manager_h}"; then
		ast_ami_major=`tr -s '[[:blank:]]' ' ' < "${ast_manager_h}" | sed -n 's/^.define AMI_VERSION "\([[0-9]][[0-9]]*\)\..*/\1/p' | head -n 1`
	fi
	ast_ami_asterisk_major=""
	case "${ast_ami_major}" in
		"")
			AC_MSG_RESULT([not found]);;
		1)
			AC_MSG_RESULT([1.x, asterisk 11 or older - deciding by header fingerprints instead]);;
		2)
			if test -f "`dirname ${ast_manager_h}`/format_cache.h"; then
				ast_ami_asterisk_major=13
			else
				ast_ami_asterisk_major=12
			fi
			AC_MSG_RESULT([2.x, asterisk ${ast_ami_asterisk_major} (format_cache.h tells 12 and 13 apart)]);;
		*)
			ast_ami_asterisk_major=`expr ${ast_ami_major} + 11`
			AC_MSG_RESULT([${ast_ami_major}.x, asterisk ${ast_ami_asterisk_major}]);;
	esac
])

dnl Source 4: the binary, for the minor that AMI_VERSION cannot give. Deliberately not the
dnl first `asterisk` on PATH, and never trusted on its own: one branch of the header search
dnl hardcodes PBX_SBINDIR=/usr/sbin, so under --with-asterisk=<some old tree> the system
dnl asterisk would answer for foreign headers (seen on the bench: 23.4.1 for the 13.38.3
dnl headers). A binary whose major disagrees with the AMI fingerprint is therefore ignored.
dnl The prefix's own sbin is tried first, with its lib dirs on LD_LIBRARY_PATH so a self-built
dnl asterisk finds its libasteriskssl.
AC_DEFUN([AST_VERSION_FROM_BINARY], [
	AC_MSG_CHECKING([for an asterisk binary next to the headers, for the exact minor])
	ast_bin=""
	ast_bin_line=""
	if test "x${cross_compiling}" != "xyes"; then
		for ast_bin_dir in "${checkdir:+${checkdir}/sbin}" "${checkdir:+${checkdir}/bin}" "${PBX_SBINDIR}"; do
			if test -z "${ast_bin}" && test -n "${ast_bin_dir}" && test -x "${ast_bin_dir}/asterisk"; then
				ast_bin_line=`LD_LIBRARY_PATH="${ast_bin_dir}/../lib:${ast_bin_dir}/../lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "${ast_bin_dir}/asterisk" -V 2>/dev/null | head -n 1`
				case "${ast_bin_line}" in
					Asterisk*) ast_bin="${ast_bin_dir}/asterisk";;
				esac
			fi
		done
	fi
	if test -n "${ast_bin}"; then
		ast_ver_str="${ast_bin_line}"
		AST_VERSION_PARSE
		if test "x${ast_ver_major}" = "x${ast_ami_asterisk_major}"; then
			AC_MSG_RESULT([${ast_bin} says '${ast_bin_line}', matching the headers])
			ASTERISK_REPOS_LOCATION=TGZ
			AST_VERSION_SET
			AST_VERSION_CHECK_BOUNDS
			AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}' (${ast_bin} -V).])
		else
			AC_MSG_RESULT([${ast_bin} says '${ast_bin_line}', but the headers are asterisk ${ast_ami_asterisk_major} - ignoring it])
			ast_ver_major=""
		fi
	else
		AC_MSG_RESULT([none])
	fi
])

dnl Source 4b: no binary, or none that matches - the AMI major alone, with minor 0.
AC_DEFUN([AST_VERSION_FROM_AMI], [
	ast_ver_major="${ast_ami_asterisk_major}"
	ast_ver_minor=0
	ast_ver_patch=0
	ast_ver_str="${ast_ver_major} (AMI ${ast_ami_major}.x)"
	ASTERISK_REPOS_LOCATION=TRUNK
	AST_VERSION_SET
	AST_VERSION_CHECK_BOUNDS
	AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}' (AMI_VERSION ${ast_ami_major}.x; the minor is unknown this way).])
])


dnl Source 5: the header fingerprints. This is the oldest detection in the file; it used to sit
dnl in the not-found branch of the autoconfig.h check, which never runs on any real install
dnl (autoconfig.h is always there), so it never ran at all. Kept for what AMI_VERSION cannot
dnl tell apart: asterisk 11 and older.
AC_DEFUN([AST_VERSION_FROM_HEADER_FINGERPRINTS], [
	AC_MSG_NOTICE([deciding the asterisk version by header fingerprints])
			HEADER_INCLUDE="
	#define HAVE_ARPA_INET_H 1
	#define AST_MODULE_SELF_SYM __internal_chan_sccp_la_self
	#define AST_MODULE "chan_sccp"
	#include <asterisk.h>
	"
			AC_CHECK_HEADER([asterisk/ast_version.h],
			[
				AC_EGREP_CPP([8.0.0], [
					$HEADER_INCLUDE
					#include <asterisk/manager.h>
					#if defined AMI_VERSION
					  AMI_VERSION
					#endif
				],
				[
					ASTERISK_VER_GROUP=119
					ASTERISK_VERSION_NUMBER=11900
					ASTERISK_REPOS_LOCATION=TRUNK

					AC_DEFINE([ASTERISK_CONF_1_19], [1], [Defined ASTERISK_CONF_1_19])
					AC_DEFINE([ASTERISK_VERSION_NUMBER], [11900], [ASTERISK Version Number])
					AC_DEFINE([ASTERISK_VERSION_GROUP], [119], [ASTERISK Version Group])
					AC_DEFINE([ASTERISK_REPOS_LOCATION], ["TRUNK"],[ASTERISK Source Location])
					
					version_found=1
					AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
				],
				[
					AC_CHECK_HEADER([asterisk/res_audiosocket.h],
					[
						ASTERISK_VER_GROUP=118
						ASTERISK_VERSION_NUMBER=11800
						ASTERISK_REPOS_LOCATION=TRUNK

						AC_DEFINE([ASTERISK_CONF_1_18], [1], [Defined ASTERISK_CONF_1_18])
						AC_DEFINE([ASTERISK_VERSION_NUMBER], [11800], [ASTERISK Version Number])
						AC_DEFINE([ASTERISK_VERSION_GROUP], [118], [ASTERISK Version Group])
						AC_DEFINE([ASTERISK_REPOS_LOCATION], ["TRUNK"],[ASTERISK Source Location])
						
						version_found=1
						AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
					],
					[
						AC_CHECK_HEADER([asterisk/iostream.h],
						[
							AC_EGREP_CPP([enhances], [
								$HEADER_INCLUDE
								#include <asterisk/module.h>
							],[
								AC_EGREP_CPP([ast_bridges\(void\)], [
									$HEADER_INCLUDE
									#include <asterisk/module.h>
									#include <asterisk/iostream.h>
									#include <asterisk/bridge.h>
								], 
								[
									ASTERISK_VER_GROUP=117
									ASTERISK_VERSION_NUMBER=11700
									ASTERISK_REPOS_LOCATION=TRUNK

									AC_DEFINE([ASTERISK_CONF_1_17], [1], [Defined ASTERISK_CONF_1_17])
									AC_DEFINE([ASTERISK_VERSION_NUMBER], [11700], [ASTERISK Version Number])
									AC_DEFINE([ASTERISK_VERSION_GROUP], [117], [ASTERISK Version Group])
									AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-17"],[ASTERISK Source Location])
									
									version_found=1
									AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
								],
								[
									ASTERISK_VER_GROUP=116
									ASTERISK_VERSION_NUMBER=11600
									ASTERISK_REPOS_LOCATION=TRUNK

									AC_DEFINE([ASTERISK_CONF_1_16], [1], [Defined ASTERISK_CONF_1_16])
									AC_DEFINE([ASTERISK_VERSION_NUMBER], [11600], [ASTERISK Version Number])
									AC_DEFINE([ASTERISK_VERSION_GROUP], [116], [ASTERISK Version Group])
									AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-16"],[ASTERISK Source Location])
									
									version_found=1
									AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
								])
							],[
								ASTERISK_VER_GROUP=115
								ASTERISK_VERSION_NUMBER=11500
								ASTERISK_REPOS_LOCATION=TRUNK

								AC_DEFINE([ASTERISK_CONF_1_15], [1], [Defined ASTERISK_CONF_1_15])
								AC_DEFINE([ASTERISK_VERSION_NUMBER], [11500], [ASTERISK Version Number])
								AC_DEFINE([ASTERISK_VERSION_GROUP], [115], [ASTERISK Version Group])
								AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-15"],[ASTERISK Source Location])
								
								version_found=1
								AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
							])
						],
						[
							AC_CHECK_HEADER([asterisk/media_cache.h],
							[
								ASTERISK_VER_GROUP=114
								ASTERISK_VERSION_NUMBER=11400
								ASTERISK_REPOS_LOCATION=TRUNK

								AC_DEFINE([ASTERISK_CONF_1_14], [1], [Defined ASTERISK_CONF_1_14])
								AC_DEFINE([ASTERISK_VERSION_NUMBER], [11400], [ASTERISK Version Number])
								AC_DEFINE([ASTERISK_VERSION_GROUP], [114], [ASTERISK Version Group])
								AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-14"],[ASTERISK Source Location])
								
								version_found=1
								AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
							],
							[
								AC_CHECK_HEADER([asterisk/format_cache.h],
								[
									ASTERISK_VER_GROUP=113
									ASTERISK_VERSION_NUMBER=11300
									ASTERISK_REPOS_LOCATION=TRUNK

									AC_DEFINE([ASTERISK_CONF_1_13], [1], [Defined ASTERISK_CONF_1_13])
									AC_DEFINE([ASTERISK_VERSION_NUMBER], [11300], [ASTERISK Version Number])
									AC_DEFINE([ASTERISK_VERSION_GROUP], [113], [ASTERISK Version Group])
									AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-14"],[ASTERISK Source Location])
									
									version_found=1
									AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}'.])
								],
								[
									AC_CHECK_HEADER([asterisk/uuid.h],
									[
										ASTERISK_VER_GROUP=112
										ASTERISK_VERSION_NUMBER=11200
										ASTERISK_REPOS_LOCATION=TRUNK

										AC_DEFINE([ASTERISK_CONF_1_12], [1], [Defined ASTERISK_CONF_1_12])
										AC_DEFINE([ASTERISK_VERSION_NUMBER], [11200], [ASTERISK Version Number])
										AC_DEFINE([ASTERISK_VERSION_GROUP], [112], [ASTERISK Version Group])
										AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-12"],[ASTERISK Source Location])
										
										version_found=1
										AC_MSG_RESULT([done])
									],[
										ASTERISK_VER_GROUP=111
										ASTERISK_VERSION_NUMBER=11100
										ASTERISK_REPOS_LOCATION=BRANCH

										AC_DEFINE([ASTERISK_CONF_1_11], [1], [Defined ASTERISK_CONF_1_11])
										AC_DEFINE([ASTERISK_VERSION_NUMBER], [11100], [ASTERISK Version Number])
										AC_DEFINE([ASTERISK_VERSION_GROUP], [111], [ASTERISK Version Group])
										AC_DEFINE([ASTERISK_REPOS_LOCATION], ["branch-11"],[ASTERISK Source Location])
										
										version_found=1
										AC_MSG_RESULT([done])
										AC_MSG_RESULT([Found 'Asterisk Version 11'])
									])
								])
							])
						], [$HEADER_INCLUDE])
					], [$HEADER_INCLUDE])
				], [$HEADER_INCLUDE])
			],[
				AC_MSG_RESULT(['ASTERISK_VERSION could not be established'])
			], [$HEADER_INCLUDE])
])

AC_DEFUN([AST_GET_VERSION], [
	CONFIGURE_PART([Checking Asterisk Version:])
	REALTIME_USEABLE=1
	version_found=0
	ast_ver_str=""
	ast_ver_major=""
	ast_ver_minor=""
	ast_ver_patch=""

	AC_ARG_WITH(asterisk_version,
	AC_HELP_STRING([--with-asterisk-version[=PATH]], [specify the asterisk_version manually (fmt=major.minor)]), [ac_cv_use_asterisk_version="${withval}"], [ac_cv_use_asterisk_version="no"])
	AS_IF([test "_${ac_cv_use_asterisk_version}" != "_no"], [
		dnl Source 1: the manual override
		ast_ver_str="${ac_cv_use_asterisk_version}"
		AST_VERSION_PARSE
		if test -z "${ast_ver_major}"; then
			AC_MSG_ERROR([--with-asterisk-version='${ac_cv_use_asterisk_version}' does not look like major.minor])
		fi
		ASTERISK_REPOS_LOCATION=TRUNK
		AST_VERSION_SET
		AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}' (--with-asterisk-version).])
	], [
		dnl Source 2: PACKAGE_VERSION. asterisk/version.h + the ASTERISK_VERSION macro is how this
		dnl used to be detected, but that header is a hard #error ("use asterisk/ast_version.h
		dnl instead") on everything from 13 up, and ast_version.h only exposes the version via
		dnl *functions* (ast_get_version()), not a preprocessor-time macro - so it can't be
		dnl probed this compile+grep way at all. asterisk/autoconfig.h's PACKAGE_VERSION (a
		dnl plain autotools convention) is the compile-time-visible replacement; it is the bare
		dnl major ("23") where asterisk's configure.ac writes one, and "trunk" where it doesn't.
		AC_CHECK_HEADER([asterisk/autoconfig.h],[
			AC_MSG_CHECKING([version in asterisk/autoconfig.h])
			AC_COMPILE_IFELSE(
				[AC_LANG_PROGRAM(
					[
						#define AST_MODULE_SELF_SYM "__internal_chan_sccp_la_self"
						#define AST_MODULE "chan_sccp"
						#include <asterisk/autoconfig.h>
					],[
						const char *test_src = PACKAGE_VERSION;
					]
				)],[
				# autoconfig.h is complex enough that gcc's preprocessor splits the
				# `test_src = PACKAGE_VERSION;` assignment across two output lines
				# with a `# <N> "file" 3 4` line-marker directive in between (this
				# didn't happen with the old, much simpler asterisk/version.h).
				# A single-line `grep test_src | grep -o` misses the value entirely
				# since it ends up on the *next* line, not test_src's own line -
				# discovered by testing on real preprocessor output on 2026-08-14,
				# not assumed. Look 2 lines past the match, drop any line-marker
				# lines (they start with '#' and would also match, wrongly, on the
				# quoted source filename inside them), then extract the quoted value.
				pbx_ver=$(eval "$ac_cpp conftest.$ac_ext" 2>/dev/null | $EGREP -A2 test_src | $EGREP -v '^#' | $EGREP -o '\".*\"')

				# process tgz, branch, trunk
				if echo $pbx_ver|grep -q "\"SVN-branch"; then
					ASTERISK_REPOS_LOCATION=BRANCH
				elif echo $pbx_ver|grep -q "\"SVN-trunk"; then
					ASTERISK_REPOS_LOCATION=TRUNK
				else
					ASTERISK_REPOS_LOCATION=TGZ
				fi
				pbx_ver=`echo ${pbx_ver} | sed 's/"//g'`

				ast_ver_str="${pbx_ver}"
				AST_VERSION_PARSE
				if test -n "${ast_ver_major}"; then
					AST_VERSION_SET
					AST_VERSION_CHECK_BOUNDS
					AC_MSG_RESULT([Found 'Asterisk Version ${ASTERISK_VERSION_NUMBER}' (PACKAGE_VERSION '${pbx_ver}').])
				else
					AC_MSG_RESULT([PACKAGE_VERSION is '${pbx_ver}', which carries no version number])
				fi
			],[
				AC_MSG_RESULT([asterisk/autoconfig.h does not compile, PACKAGE_VERSION cannot be read])
			])
		], [
			AC_MSG_RESULT([asterisk/autoconfig.h not found])
		])
		dnl Sources 3-5, only when the headers themselves did not say. The AMI major comes
		dnl first because it is read from the very headers being built against; the binary
		dnl may only add the minor, and only when it agrees on the major.
		if test ${version_found} = 0; then
			AST_VERSION_AMI_MAJOR
		fi
		if test ${version_found} = 0 && test -n "${ast_ami_asterisk_major}"; then
			AST_VERSION_FROM_BINARY
		fi
		if test ${version_found} = 0 && test -n "${ast_ami_asterisk_major}"; then
			AST_VERSION_FROM_AMI
		fi
		if test ${version_found} = 0; then
			AST_VERSION_FROM_HEADER_FINGERPRINTS
		fi
	])

	if test $version_found == 0; then
		echo ""
		echo ""
		echo "PBX branch version could not be determined"
		echo "==================================="
		echo "Either install asterisk and asterisk-devel packages using your package manager."
		echo "If you compiled asterisk manually, make sure you also run `make install-headers` so chan-sccp can find them."
		echo "Or specify the location where asterisk can be found, using ./configure --with-asterisk=[path]"
		echo ""
		echo "=================================== config.log"
		cat config.log 
		echo "=================================== config.log"
		exit 255
	fi
])

dnl Find Asterisk Header Files
AC_DEFUN([AST_CHECK_HEADERS],[
	CONFIGURE_PART([Checking Asterisk Headers:])

	CFLAGS_backup={$CFLAGS}
	CFLAGS="${CFLAGS_saved}"
	AX_APPEND_COMPILE_FLAGS([-Werror=incompatible-pointer-types -Werror=implicit-function-declaration -Werror=int-conversion -Werror=implicit-function-declaration -Werror-shadow], TEST_SUPPORTED_CFLAGS)
	CFLAGS="${CFLAGS_saved} ${TEST_SUPPORTED_CFLAGS}"
dnl	CFLAGS="${CFLAGS_saved} -Werror=incompatible-pointer-types -Werror=implicit-function-declaration -Werror=int-conversion"
dnl 	CFLAGS="${CFLAGS_saved} -Werror=implicit-function-declaration"
	ASTOBJ2_AVAILABLE="no"
	
	HEADER_INCLUDE="
#undef PACKAGE
#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_VERSION
#undef VERSION
#define AST_MODULE_SELF_SYM __internal_chan_sccp_la_self
#define AST_MODULE "chan_sccp"
#if ASTERISK_VERSION_NUMBER >= 10400
#  include <asterisk.h>
#endif
#include <asterisk/autoconfig.h>
#include <asterisk/buildopts.h>
"
	SANITIZE_CFLAGS=""
	SANITIZE_LDFLAGS=""
	MWI_USE_EVENTS=0
	AC_CHECK_HEADER([asterisk.h],
		AC_MSG_CHECKING([ - if asterisk provides ast_register_file_version...])
		AC_EGREP_CPP([ast_register_file_version], [
			$HEADER_INCLUDE
		],[
			AC_DEFINE([CS_AST_REGISTER_FILE_VERSION],1,['CS_AST_REGISTER_FILE_VERSION' available])
			AC_MSG_RESULT(yes)
		],[
			AC_MSG_RESULT(no)
		])
	)
	AC_CHECK_HEADER([asterisk/autoconfig.h],
		AC_MSG_CHECKING([ - AST_XML_DOCS defined in asterisk/autoconfig.h...])
		AC_EGREP_CPP([yes], [
			$HEADER_INCLUDE
			#if defined(AST_XML_DOCS)
				yes
			#endif
		],[
			AC_DEFINE([CS_AST_XML_DOCS],1,['AST_XML_DOCS' available])
			AC_MSG_RESULT(yes)
		],[
			AC_MSG_RESULT(no)
		])
		AC_MSG_CHECKING([ - HAVE_BKTR defined in asterisk/autoconfig.h...])
		AC_EGREP_CPP([yes],   [
			#include "asterisk/autoconfig.h"
			#if defined(HAVE_BKTR)
				yes
			#endif], 
		[
			AC_DEFINE([HAVE_BKTR],1,[defined 'HAVE_BKTR'])
			AC_MSG_RESULT(yes)
		], [
			AC_MSG_RESULT(no)
		])
	)
	AC_CHECK_HEADER([asterisk/lock.h],
		[
			lock_compiled=yes
			AC_DEFINE(HAVE_PBX_LOCK_H,1,[Found 'asterisk/lock.h'])
		],[
			lock_compiled=no
		],[	
			$HEADER_INCLUDE
		]
	)

	AS_IF([test "${lock_compiled}" != "no"], [
		AC_DEFINE([PBX_CHANNEL_TYPE],[struct ast_channel],[Define PBX_CHANNEL_TYPE as 'struct ast_channel'])
		AC_CHECK_HEADER([asterisk/acl.h],
		[
			AC_DEFINE(HAVE_PBX_ACL_H,1,[Found 'asterisk/acl.h'])
			CS_CHECK_AST_TYPEDEF([struct ast_ha],[asterisk/acl.h],AC_DEFINE([CS_AST_HA],1,['struct ast_ha' available]))
		],,[
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/buildopts.h], 
		[
			AC_MSG_CHECKING([ - if asterisk was compiled with the 'LOW_MEMORY' buildoptions...])
			AC_EGREP_CPP([yes], [
				include "asterisk/buildopts.h"
				#if defined(LOW_MEMORY)
					yes
				#endif
			],[
				AC_DEFINE([CS_LOW_MEMORY],1,[asterisk compiled with 'LOW_MEMORY'])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])

			AC_MSG_CHECKING([ - if asterisk was compiled with the 'TEST_FRAMEWORK' buildoptions...])
			AC_EGREP_CPP([yes], [
				#include "asterisk/buildopts.h"
				#if defined(TEST_FRAMEWORK)
					yes
				 #endif
			], [
				AC_DEFINE([CS_TEST_FRAMEWORK],1,[asterisk compiled with 'TEST_FRAMEWORK'])
				TEST_FRAMEWORK=yes
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
				TEST_FRAMEWORK=no
			])
			AC_SUBST([TEST_FRAMEWORK])

			SANITIZE_CFLAGS=""
			SANITIZE_LDFLAGS=""
			AC_MSG_CHECKING([ - checking for ADDRESS_SANITIZER in buildoptions...])
			AC_EGREP_CPP([yes],   [
				#include "asterisk/buildopts.h"
				#if defined(ADDRESS_SANITIZER)
					yes
				#endif], 
			[
				SANITIZE_CFLAGS="-fsanitize=address"
				SANITIZE_LDFLAGS="-fno-omit-frame-pointer -fsanitize=address"
				AC_MSG_RESULT(yes)
			], [
				AC_MSG_RESULT(no)
			])
			AC_MSG_CHECKING([ - checking for THREAD_SANITIZER in buildoptions...])
			AC_EGREP_CPP([yes],   [
				#include "asterisk/buildopts.h"
				#if defined(THREAD_SANITIZER)
					yes
				#endif], 
			[
				SANITIZE_CFLAGS="-fsanitize=thread -pie -fPIE"
				SANITIZE_LDFLAGS="-fno-omit-frame-pointer -fsanitize=thread"
				AC_MSG_RESULT(yes)
			], [
				AC_MSG_RESULT(no)
			])
			AC_MSG_CHECKING([ - checking for LEAK_SANITIZER in buildoptions...])
			AC_EGREP_CPP([yes],   [
				#include "asterisk/buildopts.h"
				#if defined(LEAK_SANITIZER)
					yes
				#endif], 
			[
				SANITIZE_CFLAGS="$SANITIZE_CFLAGS -fsanitize=leak"
				SANITIZE_LDFLAGS="$SANITIZE_LDFLAGS -fno-omit-frame-pointer -fsanitize=leak"
				AC_MSG_RESULT(yes)
			], [
				AC_MSG_RESULT(no)
			])
			AC_MSG_CHECKING([ - checking for UNDEFINED_SANITIZER in buildoptions...])
			AC_EGREP_CPP([yes],   [
				#include "asterisk/buildopts.h"
				#if defined(UNDEFINED_SANITIZER)
					yes
				#endif], 
			[
				SANITIZE_CFLAGS="$SANITIZE_CFLAGS -fsanitize=undefined"
				SANITIZE_LDFLAGS="$SANITIZE_LDFLAGS -fno-omit-frame-pointer -fsanitize=undefined"
				AC_MSG_RESULT(yes)
			], [
				AC_MSG_RESULT(no)
			])
		],,[
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/astobj2.h],
		[
			AC_DEFINE(HAVE_PBX_ASTOBJ2_H,1,[Found 'asterisk/astobj2.h'])
			ASTOBJ2_AVAILABLE="yes"
		],,[
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/abstract_jb.h],
		[
			AC_DEFINE(HAVE_PBX_ABSTRACT_JB_H,1,[Found 'asterisk/abstract_jb.h'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_jb.target_extra'...],[ac_cv_ast_jb_target_extra],[
					$HEADER_INCLUDE
					#include <asterisk/abstract_jb.h>
				], [
					struct ast_jb_conf __attribute__((unused)) test_jbconf;
					test_jbconf.target_extra = (long)1;
				], 
				[CS_AST_JB_TARGETEXTRA],['CS_AST_JB_TARGETEXTRA' available]
			)						
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/linkedlists.h],	AC_DEFINE(HAVE_PBX_LINKEDLISTS_H,1,[Found 'asterisk/linkedlists.h']),,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/app.h],
		[
			AC_DEFINE(HAVE_PBX_APP_H,1,[Found 'asterisk/app.h'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_app_has_voicemail'...],[ac_cv_ast_app_has_voicemail],[
					$HEADER_INCLUDE
					#ifdef HAVE_PBX_LINKEDLISTS_H
					#include <asterisk/linkedlists.h>
					#endif		
					#include <asterisk/app.h>
				], [
					int __attribute__((unused)) test_vm = ast_app_has_voicemail(NULL, NULL);
				], [CS_AST_HAS_NEW_VOICEMAIL],['ast_app_has_voicemail' available]
			)

			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_app_separate_args'...],[ac_cv_ast_app_seperate_args], [
					$HEADER_INCLUDE
					#ifdef HAVE_PBX_LINKEDLISTS_H
					#include <asterisk/linkedlists.h>
					#endif		
					#include <asterisk/app.h>
				], [
					unsigned int __attribute__((unused)) test_args = ast_app_separate_args(NULL, NULL, NULL, 0);
				], [CS_AST_HAS_APP_SEPARATE_ARGS],['ast_app_separate_args' available]
			)
			if test $ac_cv_ast_app_seperate_args = yes; then
				AC_DEFINE(sccp_app_separate_args(x,y,z,w),ast_app_separate_args(x,y,z,w),[Found 'ast_app_separate_args' in asterisk/app.h])
			fi
		],,[
			$HEADER_INCLUDE
			#ifdef HAVE_PBX_LINKEDLISTS_H
			#include <asterisk/linkedlists.h>
			#endif		
		])
		AC_CHECK_HEADER([asterisk/channel.h],
		[
			AC_DEFINE(HAVE_PBX_CHANNEL_H,1,[Found 'asterisk/channel.h'])

			CS_CV_TRY_COMPILE_IFELSE([ - availability 'struct ast_channel_tech'...],[ac_cv_ast_channel_tech], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
			], [
				int x = sizeof(struct ast_channel_tech); x = x;
			], [
				AC_DEFINE([CS_AST_HAS_TECH_PVT],1,['struct ast_channel_tech' available'])
				AC_DEFINE([CS_AST_CHANNEL_PVT(_x)],[((sccp_channel_t*)(_x)->tech_pvt)],['defined channel pvt'])
				AC_DEFINE([CS_AST_CHANNEL_PVT_TYPE(_x)],[(_x)->tech->type],['defined channel_pvt_type'])
				AC_DEFINE([CS_AST_CHANNEL_PVT_CMP_TYPE(_x,_y)],[!strncasecmp((_x)->tech->type, (_y), strlen((_y)))],['defined cmp_type'])
			], [
				AC_DEFINE([CS_AST_HAS_TECH_PVT],0,['struct ast_channel_tech' available'])
				AC_DEFINE([CS_AST_CHANNEL_PVT(_x)],[((sccp_channel_t*)(_x)->pvt->pvt)],['defined channel pvt'])
				AC_DEFINE([CS_AST_CHANNEL_PVT_TYPE(_x)],[(_x)->type],['defined channel_pvt_type'])
				AC_DEFINE([CS_AST_CHANNEL_PVT_CMP_TYPE(_x,_y)],[!strncasecmp((_x)->type, (_y), strlen((_y)))],['defined cmp_type'])
			])
			AC_DEFINE([CS_AST_CHANNEL_PVT_IS_SCCP(_x)],[CS_AST_CHANNEL_PVT_CMP_TYPE((_x),"SCCP")], ['defined pvt_is_sccp'])

			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_bridged_channel'...],[ac_cv_ast_bridged_channel],[
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				], [
					struct ast_channel __attribute__((unused)) *test_bridged_channel = ast_bridged_channel(NULL);
				], [CS_AST_HAS_BRIDGED_CHANNEL],['ast_bridged_channel' available]
			)

			AC_MSG_CHECKING([ - availability 'ast_channel_bridge_peer' in asterisk/channel.h...])
			AC_EGREP_CPP([ast_channel_bridge_peer], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
			],[
				AC_DEFINE([CS_AST_HAS_CHANNEL_BRIDGE_PEER],1,['ast_channel_bridge_peer' available])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])

			AC_MSG_CHECKING([ - availability 'ast_channel_get_bridge_channel' in asterisk/channel.h...])
			AC_EGREP_CPP([ast_channel_get_bridge_channel], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
			],[
				AC_DEFINE([CS_AST_HAS_CHANNEL_GET_BRIDGE_CHANNEL], 1 ,['ast_channel_get_bridge_channel' available])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
			
			CS_CHECK_AST_TYPEDEF([struct ast_callerid],[asterisk/channel.h],AC_DEFINE([CS_AST_CHANNEL_HAS_CID],1,['struct ast_callerid' available]))
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_flag_moh'...],[ac_cv_ast_flag_moh], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				], [
					int __attribute__((unused)) test_moh = (int)AST_FLAG_MOH;
				], [CS_AST_HAS_FLAG_MOH],['AST_FLAG_MOH' available]
			)

			dnl CS_CV_TRY_COMPILE_IFELSE([ - availability 'ast_max_extension'...], [ac_cv_ast_max_context], [
			dnl 	$HEADER_INCLUDE
			dnl 		#include <asterisk/channel.h>
			dnl 	], [
			dnl 		int test_context = (int)AST_MAX_EXTENSION;
			dnl 	], [AC_DEFINE([SCCP_MAX_EXTENSION],[AST_MAX_EXTENSION],['using SCCP_MAX_EXTENSION = AST_MAX_EXTENSION'])
			dnl 	], [AC_DEFINE([SCCP_MAX_EXTENSION],[80],['defined SCCP_MAX_EXTENSION = 80'])
			dnl ])
			AC_DEFINE([SCCP_MAX_EXTENSION],[80],['defined SCCP_MAX_EXTENSION = 80'])	dnl to be done: required actual lookup in asterisk
			AC_DEFINE([SCCP_MAX_AUX],[16],['defined SCCP_MAX_AUX = 16'])			dnl to be done: required actual lookup in asterisk
			AC_DEFINE([SCCP_MAX_MUSICCLASS],[SCCP_MAX_EXTENSION],['MAX_MUSICCLASS' = SCCP_MAX_EXTENSION])
			AC_DEFINE([SCCP_MAX_LANGUAGE],[SCCP_MAX_EXTENSION],['MAX_MUSICCLASS' = SCCP_MAX_EXTENSION])
			AC_DEFINE([SCCP_MAX_CONTEXT],[SCCP_MAX_EXTENSION],['defined SCCP_MAX_CONTEXT = SCCP_MAX_EXTENSION'])
			AC_DEFINE([SCCP_MAX_HOSTNAME_LEN],[SCCP_MAX_EXTENSION],['defined SCCP_MAX_HOSTNAME_LEN = SCCP_MAX_EXTENSION'])
			AC_DEFINE([SCCP_MAX_LABEL],[SCCP_MAX_EXTENSION],['defined SCCP_MAX_LABEL = SCCP_MAX_EXTENSION'])
			AC_DEFINE([SCCP_MAX_MESSAGESTACK],[10],['defined SCCP_MAX_MESSAGESTACK = 10'])
			AC_DEFINE([SCCP_MAX_SOFTKEYSET_NAME],[48],['defined SCCP_MAX_SOFTKEYSET_NAME = 48'])
			AC_DEFINE([SCCP_MAX_SOFTKEY_MASK],[16],['defined SCCP_MAX_SOFTKEY_MASK = 16'])
			AC_DEFINE([SCCP_MAX_SOFTKEY_MODES],[16],['defined SCCP_MAX_SOFTKEY_MODES = 16'])
			AC_DEFINE([SCCP_MAX_DEVICE_DESCRIPTION],[40],['defined SCCP_MAX_DEVICE_DESCRIPTION = 40'])
			AC_DEFINE([SCCP_MAX_DEVICE_CONFIG_TYPE],[16],['defined SCCP_MAX_DEVICE_CONFIG_TYPE = 16'])
			AC_DEFINE([SCCP_MAX_BUTTON_OPTIONS],[256],['defined SCCP_MAX_BUTTON_OPTIONS = 256'])
			AC_DEFINE([SCCP_MAX_DEVSTATE_SPECIFIER],[256],['defined SCCP_MAX_DEVSTATE_SPECIFIER = 256'])
			AC_DEFINE([SCCP_MAX_LINE_ID],[8],['defined SCCP_MAX_LINE_ID = 8'])
			AC_DEFINE([SCCP_MAX_LINE_PIN],[8],['defined SCCP_MAX_LINE_PIN = 8'])
			AC_DEFINE([SCCP_MAX_SECONDARY_DIALTONE_DIGITS],[10],['defined SCCP_MAX_SECONDARY_DIALTONE_DIGITS = 10'])
			AC_DEFINE([SCCP_MAX_DATE_FORMAT],[8],['defined SCCP_MAX_DATE_FORMAT = 8'])
			AC_DEFINE([SCCP_MAX_REALTIME_TABLE_NAME],[45],['defined SCCP_MAX_REALTIME_TABLE_NAME = 45'])
			AC_DEFINE_UNQUOTED([SCCP_MAX_MAILBOX_UNIQUEID],[(SCCP_MAX_EXTENSION + SCCP_MAX_CONTEXT + 2)],['defined SCCP_MAX_MAILBOX_UNIQUEID'])

			CS_CV_TRY_COMPILE_IFELSE([ - availability 'ast_max_account_code'...], [ac_cv_ast_max_account_code], [
				$HEADER_INCLUDE
					#include <asterisk/channel.h>
				], [
					int __attribute__((unused)) test_account_code = (int)AST_MAX_ACCOUNT_CODE;
				],
				[AC_DEFINE([SCCP_MAX_ACCOUNT_CODE],[AST_MAX_ACCOUNT_CODE],[Found 'AST_MAX_ACCOUNT_CODE' in asterisk/channel.h])],
				[AC_DEFINE([SCCP_MAX_ACCOUNT_CODE],[50],['AST_MAX_ACCOUNT_CODE' replacement = 50])]
			)

			CS_CV_TRY_COMPILE_IFELSE([ - availability 'ast_namedgroups'...], [ac_cv_ast_namedgroups], [
				$HEADER_INCLUDE
					#include <asterisk/channel.h>
				], [
					struct ast_namedgroups __attribute__((unused)) *test = ast_get_namedgroups("test");
				],
				[AC_DEFINE([CS_AST_HAS_NAMEDGROUP],1,[Found 'ast_namedgroups' in asterisk/channel.h])],
			)
			CS_CHECK_AST_TYPEDEF([ast_callid],[asterisk/channel.h], AC_DEFINE([CS_AST_CHANNEL_CALLID_TYPEDEF],1,['ast_channel_callid' returns struct]))
		],,[
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/bridge.h],
		[
			AC_MSG_CHECKING([ - availability 'ast_bridge_base_new' in asterisk/bridge.h...])
			AC_EGREP_CPP([ast_bridge_base_new], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				#include <asterisk/linkedlists.h>
				#include <asterisk/astobj2.h>
				#include <asterisk/bridge.h>
			],[
				AC_DEFINE([CS_BRIDGE_BASE_NEW],1,[Found 'ast_bridge_base_new' in asterisk/bridge.h])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
			AC_MSG_CHECKING([ - availability 'AST_BRIDGE_JOIN_PASS_REFERENCE' in ast_bridge_join...])
			AC_EGREP_CPP([AST_BRIDGE_JOIN_PASS_REFERENCE], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				#include <asterisk/linkedlists.h>
				#include <asterisk/astobj2.h>
				#include <asterisk/bridge.h>
			],[
				AC_DEFINE([CS_BRIDGE_JOIN_PASSREFERENCE],1,[Found 'AST_BRIDGE_JOIN_PASS_REFERENCE' in definition of ast_bridge_join' in asterisk/bridge.h])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
			CS_CV_TRY_COMPILE_IFELSE([ - ast_bridge_depart with only one parameter...], [ac_cv_ast_bridge_depart], [
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				#include <asterisk/linkedlists.h>
				#include <asterisk/astobj2.h>
				#include <asterisk/bridge.h>
			], [
				struct ast_channel *chan = {0};
				//struct ast_bridge __attribute__((unused)) *test_bridge = ast_bridge_depart(chan);
				int __attribute__((unused)) test_bridge = ast_bridge_depart(chan);
			], [
				AC_DEFINE([CS_BRIDGE_DEPART_ONLY_CHANNEL],1,['ast_bridge_depart' only needs channel reference in asterisk/bridge.h])
			])
		],[
			AC_CHECK_HEADER([asterisk/bridging.h],
			[
				AC_CHECK_HEADER([asterisk/bridging_roles.h], [
					AC_DEFINE(HAVE_PBX_BRIDGING_ROLES_H,1,[Found 'asterisk/bridging_roles.h'])
					],,[
					$HEADER_INCLUDE
					#include <asterisk/channel.h>
					#include <asterisk/linkedlists.h>
					#include <asterisk/astobj2.h>
					#include <asterisk/bridging.h>
				])
				AC_MSG_CHECKING([ - availability 'ast_bridge_base_new' in asterisk/bridging.h...])
				AC_EGREP_CPP([ast_bridge_base_new], [
					$HEADER_INCLUDE
					#include <asterisk/channel.h>
					#include <asterisk/linkedlists.h>
					#include <asterisk/astobj2.h>
					#include <asterisk/bridging.h>
				],[
					AC_DEFINE([CS_BRIDGE_BASE_NEW],1,[Found 'ast_bridge_base_new' in asterisk/bridging.h])
					AC_MSG_RESULT(yes)
				],[
					AC_MSG_RESULT(no)
				])
				AC_MSG_CHECKING([ - availability 'AST_BRIDGE_CAPABILITY_MULTITHREADED' in asterisk/bridging.h...])
				AC_EGREP_CPP([AST_BRIDGE_CAPABILITY_MULTITHREADED], [
					$HEADER_INCLUDE
					#include <asterisk/channel.h>
					#include <asterisk/linkedlists.h>
					#include <asterisk/astobj2.h>
					#include <asterisk/bridging.h>
				],[
					AC_DEFINE([CS_BRIDGE_CAPABILITY_MULTITHREADED],1,[Found 'AST_BRIDGE_CAPABILITY_MULTITHREADED' in asterisk/bridging.h])
					AC_MSG_RESULT(yes)
				],[
					AC_MSG_RESULT(no)
				])
				AC_MSG_CHECKING([ - availability 'pass_reference' in ast_bridge_join...])
				AC_EGREP_CPP([int pass_reference], [
					$HEADER_INCLUDE
					#include <asterisk/channel.h>
					#include <asterisk/linkedlists.h>
					#include <asterisk/astobj2.h>
					#include <asterisk/bridging.h>
				],[
					AC_DEFINE([CS_BRIDGE_JOIN_PASSREFERENCE],1,[Found 'pass_reference' in definition of ast_bridge_join' in asterisk/bridging.h])
					AC_MSG_RESULT(yes)
				],[
					AC_MSG_RESULT(no)
				])

				CS_CV_TRY_COMPILE_IFELSE([ - ast_bridge_depart with only one parameter...], [ac_cv_ast_bridge_depart], [
					$HEADER_INCLUDE
					#include <asterisk/channel.h>
					#include <asterisk/linkedlists.h>
					#include <asterisk/astobj2.h>
					#include <asterisk/bridging.h>
					], [
						struct ast_channel *chan = {0};
						struct ast_bridge __attribute__((unused)) *test_bridge = ast_bridge_depart(chan);
					], 
					[AC_DEFINE([CS_BRIDGE_DEPART_ONLY_CHANNEL],1,['ast_bridge_depart' only needs channel reference in asterisk/bridging.h])],
				)
			],,[ 
				$HEADER_INCLUDE
				#include <asterisk/channel.h>
				#include <asterisk/linkedlists.h>
				#include <asterisk/astobj2.h>
			])
		],[
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/channel_pvt.h],
		[
			AC_DEFINE(HAVE_PBX_CHANNEL_pvt_H,1,[Found 'asterisk/channel_pvt.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_DEFINE(PBX_VARIABLE_TYPE,[struct ast_variable],[Defined PBX_VARIABLE as 'struct ast_variable'])
		AC_CHECK_HEADER([asterisk/devicestate.h],
		[
			AC_DEFINE(HAVE_PBX_DEVICESTATE_H,1,[Found 'asterisk/devicestate.h'])			
			DEVICESTATE_H=yes
			
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_devstate_changed'...], [ac_cv_ast_devstate_changed], [
					$HEADER_INCLUDE
					#include <asterisk/devicestate.h>
				], [
					ast_devstate_changed(AST_DEVICE_UNKNOWN, "SCCP/%s", "test");
				], [CS_DEVICESTATE],['ast_devstate_changed' available]
			)
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'cacheable ast_devstate_changed'...], [ac_cv_cacheable_ast_devstate_changed], [
					$HEADER_INCLUDE
					#include <asterisk/devicestate.h>
				], [
					ast_devstate_changed(AST_DEVICE_UNKNOWN, AST_DEVSTATE_CACHABLE, "SCCP/%s", "test");
				], [CS_CACHEABLE_DEVICESTATE],['cacheable ast_devstate_changed' available]
			)
			
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_device_ringing'...], [ac_cv_ast_device_ringing], [
					$HEADER_INCLUDE
					#include <asterisk/devicestate.h>
				], [
					int __attribute__((unused)) test_device_ringing = (int)AST_DEVICE_RINGING;
				], [CS_AST_DEVICE_RINGING],['AST_DEVICE_RINGING' available]
			)
			
			AC_MSG_CHECKING([ - availability 'ast_enable_distributed_devstate'...])
			AC_EGREP_CPP([ast_enable_distributed_devstate], [
					$HEADER_INCLUDE
					#include <asterisk/devicestate.h>
			],[
				AC_DEFINE([CS_AST_ENABLE_DISTRIBUTED_DEVSTATE],1,[Found 'ast_enable_distributed_devstate' in asterisk/devicestate.h])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/endian.h],	
		[
			AC_DEFINE([CS_AST_HAS_ENDIAN],1,[Found 'asterisk/endian.h'])
			AC_DEFINE([HAVE_PBX_ENDIAN_H],1,[Found 'asterisk/endian.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/event.h],	
		[
			AC_DEFINE(HAVE_PBX_EVENT_H,1,[Found 'asterisk/event.h'])
			CS_CV_TRY_COMPILE_IFELSE([ - availability 'ast_event_subscribe'...], [ac_cv_ast_event_subscribe], [
					$HEADER_INCLUDE
					#include <asterisk/event.h>
				], [
					ast_event_cb_t test_cb;
					void *data;
					struct ast_event_sub __attribute__((unused)) *test_event_sub = ast_event_subscribe(AST_EVENT_MWI, test_cb, "mailbox subscription", data, AST_EVENT_IE_MAILBOX, AST_EVENT_IE_PLTYPE_STR, NULL, AST_EVENT_IE_CONTEXT, AST_EVENT_IE_PLTYPE_STR, "default", AST_EVENT_IE_END);
				], [
					AC_DEFINE([CS_AST_HAS_EVENT],1, ['ast_event_subscribe' available])
					MWI_USE_EVENT=1
				]
			)

		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/stasis.h],	
		[
			AC_DEFINE(HAVE_PBX_STASIS_H,1,[Found 'asterisk/stasis.h'])
			CS_CV_TRY_COMPILE_IFELSE([ - availability 'stasis_subscribe'...], [ac_cv_ast_stasis_subscribe], [
					$HEADER_INCLUDE
					#include <asterisk/stasis.h>
				], [
					struct stasis_topic *stasis_topic = NULL;
					void *data = NULL;
					struct stasis_subscription __attribute__((unused)) *stasis_sub = stasis_subscribe(stasis_topic, data, data);
				], [
					AC_DEFINE([CS_AST_HAS_STASIS],1,['stasis_subscribe' available])
					MWI_USE_EVENT=1
				]
			)
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'stasis_subscription_set_filter'...], [ac_cv_ast_stasis_subscription_set_filter], [
					$HEADER_INCLUDE
					#include <asterisk/stasis.h>
				], [
					struct stasis_subscription *subscription = NULL;
					stasis_subscription_accept_message_type(subscription, NULL);
					stasis_subscription_set_filter(subscription, STASIS_SUBSCRIPTION_FILTER_SELECTIVE);
				], [CS_AST_HAS_STASIS_SUBSCRIPTION_SET_FILTER], ['stasis_subscription_set_filter' available]
			)
			AC_CHECK_HEADER([asterisk/stasis_endpoints.h],	
			[
				AC_DEFINE(HAVE_PBX_STASIS_H,1,[Found 'asterisk/stasis_endpoints.h'])
				CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_endpoint_create'...], [ac_cv_ast_endpoint_create], [
						$HEADER_INCLUDE
						#include <asterisk/stasis_endpoints.h>
					], [
						ast_endpoint_create("SCCP", "test1234");
					], [CS_AST_HAS_STASIS_ENDPOINT],['stasis_endpoint' available]
				)
			],,[ 
				$HEADER_INCLUDE
			])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/vector.h],	
		[
			AC_DEFINE(HAVE_PBX_VECTOR_H,1,[Found 'asterisk/vector.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/parking.h],
		[
			AC_DEFINE(HAVE_PBX_FEATURES_H,1,[Found 'asterisk/parking.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		ast_pickup_h=0
		AC_CHECK_HEADER([asterisk/pickup.h],
		[
			AC_DEFINE([HAVE_PBX_FEATURES_H],1,[Found 'asterisk/pickup.h'])
			AC_DEFINE([CS_AST_DO_PICKUP],1,[Found 'ast_do_pickup' in asterisk/pickup.h])
			ast_pickup_h=1
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/features.h],
		[
			AC_DEFINE([HAVE_PBX_FEATURES_H],1,[Found 'asterisk/features.h'])
			AS_IF([test "${ast_pickup_h}" == 0], [
				AC_MSG_CHECKING([ - availability 'ast_do_pickup'...])
				AC_EGREP_CPP([ast_do_pickup], [
					$HEADER_INCLUDE
					#include <asterisk/features.h>
				],[
					AC_DEFINE([CS_AST_DO_PICKUP],1,[Found 'ast_do_pickup' in asterisk/features.h])
					AC_MSG_RESULT(yes)
				],[
					AC_MSG_RESULT(no)
				])
			]);
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/frame.h],
		[
			AC_DEFINE([HAVE_PBX_FRAME_H],1,[Found 'asterisk/frame.h'])
			AC_DEFINE([PBX_FRAME_TYPE],[struct ast_frame],[Define PBX_FRAME as 'struct ast_frame'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_frame.data.ptr'...], [ac_cv_ast_frame_data_ptr], [
					$HEADER_INCLUDE
					#include <asterisk/frame.h>
				], [
					struct ast_frame __attribute__((unused)) test_frame = { AST_FRAME_DTMF, };
					test_frame.data.ptr = NULL;
				], [CS_AST_NEW_FRAME_STRUCT], [new frame data.ptr]
			)

			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_control_incomplete'...], [ac_cv_ast_control_incomplete], [
					$HEADER_INCLUDE
					#include <asterisk/frame.h>
				], [
					int __attribute__((unused)) test_control_incomplete = (int)AST_CONTROL_INCOMPLETE;
				], [CS_AST_CONTROL_INCOMPLETE], ['AST_CONTROL_INCOMPLETE' available]
			)
			
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_control_redirecting'...], [ac_cv_ast_control_redirecting], [
					$HEADER_INCLUDE
					#include <asterisk/frame.h>
				], [
					int __attribute__((unused)) test_control_redirecting = (int)AST_CONTROL_REDIRECTING;
				], [CS_AST_CONTROL_REDIRECTING], ['AST_CONTROL_REDIRECTING' available]
			)

		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/manager.h],	
		[
			AC_DEFINE([HAVE_PBX_MANAGER_H],1,[Found 'asterisk/manager.h'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'manager_custom_hook' is available...], [ac_cv_manager_custom_hook], [
				$HEADER_INCLUDE
				#include <asterisk/stringfields.h>
				#include <asterisk/manager.h>
				], [
					struct manager_custom_hook __attribute__((unused)) sccp_manager_hook;
				], [HAVE_PBX_MANAGER_HOOK_H], ['struct manager_custom_hook' available]
			)

			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_manager_check_enabled'...], [ac_cv_ast_manager_check_enabled], [
				$HEADER_INCLUDE
				#include <asterisk/stringfields.h>
				#include <asterisk/manager.h>
				], [
					int x = ast_manager_check_enabled();
				], [CS_AST_MANAGER_CHECK_ENABLED], ['CS_AST_MANAGER_CHECK_ENABLED' available]
			)
		],,[
			$HEADER_INCLUDE
			#include <asterisk/stringfields.h>
		])
		AC_CHECK_HEADER([asterisk/pbx.h],
		[
			AC_DEFINE([HAVE_PBX_PBX_H],1,[Found 'asterisk/pbx.h'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_get_hint'...], [ac_cv_ast_get_hint], [
				$HEADER_INCLUDE
				#ifdef HAVE_PBX_CHANNEL_H
				#include <asterisk/channel.h>
				#endif
				#include <asterisk/pbx.h>
				],[
					int __attribute__((unused)) test_get_hint = ast_get_hint("", 0, "", 0, NULL, "", "");
				],[CS_AST_HAS_NEW_HINT],['ast_get_hint' available]
			)
			
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_extension_onhold'...], [ac_cv_ast_extension_onhold], [
				$HEADER_INCLUDE
				#include <asterisk/pbx.h>
				], [
					int __attribute__((unused)) test_ext_onhold = (int)AST_EXTENSION_ONHOLD;
				], [CS_AST_HAS_EXTENSION_ONHOLD],['AST_EXTENSION_ONHOLD' available]
			)
			
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_extension_ringing'...], [ac_cv_ast_extension_ringing], [
				$HEADER_INCLUDE
				#include <asterisk/pbx.h>
				], [
					int __attribute__((unused)) test_ext_ringing = (int)AST_EXTENSION_RINGING;
				], [CS_AST_HAS_EXTENSION_RINGING],['AST_EXTENSION_RINGING' available]
			)

			AS_IF([test "${ASTERISK_VER_GROUP}" -gt "112"], [
				CFLAGS="${CFLAGS_saved} ${TEST_SUPPORTED_CFLAGS} -Werror"
				CS_CV_TRY_COMPILE_DEFINE([ - ast_state_cb_type uses const char (13)...], [ac_cv_ast_state_cb_type_const_char], [
					$HEADER_INCLUDE
					#include <asterisk/pbx.h>
					static int test_cb(const char *context, const char *exten, struct ast_state_cb_info *info, void *data) {
						return 0;
					}
					], [
						int __attribute__((unused)) id = ast_extension_state_add("","",test_cb,"");
					], [CS_AST_HAS_EXTENSION_STATE_CB_TYPE_CONST_CHAR], ['AST_EXTENSION_STATE_CB_TYPE_CONST_CHAR' available]
				)
				CS_CV_TRY_COMPILE_DEFINE([ - ast_state_cb_type uses char (11-13)...], [ac_cv_ast_state_cb_type_char], [
					$HEADER_INCLUDE
					#include <asterisk/pbx.h>
					static int test_cb(char *context, char *exten, struct ast_state_cb_info *info, void *data) {
						return 0;
					}
					], [
						int __attribute__((unused)) id = ast_extension_state_add("","",test_cb,"");
					], [CS_AST_HAS_EXTENSION_STATE_CB_TYPE_CHAR], ['AST_EXTENSION_STATE_CB_TYPE_CHAR' available]
				)
				CFLAGS="${CFLAGS_saved} ${TEST_SUPPORTED_CFLAGS}"
			])

			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_context_destroy_by_name'...], [ac_cv_ast_context_destroy_by_name], [
				$HEADER_INCLUDE
				#include <asterisk/pbx.h>
				], [
					int __attribute__((unused)) test = ast_context_destroy_by_name("xxx","xxx");
				], [CS_AST_HAS_CONTEXT_DESTROY_BY_NAME],['AST_CONTEXT_DESTROY_BY_NAME' available]
			)
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/rtp_engine.h],
		[
			AC_DEFINE([HAVE_PBX_RTP_H],1,[Found 'asterisk/rtp_engine.h'])
			AC_DEFINE([HAVE_PBX_RTP_ENGINE_H],1,[Found 'asterisk/rtp_engine.h'])
			AC_DEFINE([PBX_RTP_TYPE],[struct ast_rtp_instance],[Defined PBX_RTP_TYPE as 'struct ast_rtp_instance'])
			CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_rtp_instance_new'...], [ac_cv_ast_rtp_instance_new], [
				$HEADER_INCLUDE
				#define new avoid_cxx_new_keyword
				#include <asterisk/rtp_engine.h>
				#undef new
			], [
				const struct ast_sockaddr test_sin=NULL;
				struct ast_rtp_instance __attribute__((unused)) *test_instance = ast_rtp_instance_new(NULL, NULL, &test_sin, NULL);
			], [
				CS_AST_RTP_INSTANCE_NEW],[Found 'void ast_rtp_instance_new' in asterisk/rtp_engine.h
			])
			AC_MSG_CHECKING([ - availability 'ast_rtp_instance_bridge'...])
			AC_EGREP_CPP([ast_rtp_instance_bridge], [
				$HEADER_INCLUDE
				#define new avoid_cxx_new_keyword
				#include <asterisk/rtp_engine.h>
				#undef new
			],[
				AC_DEFINE([CS_AST_RTP_INSTANCE_BRIDGE],1,[Found 'ast_rtp_instance_bridge' in asterisk/bridging.h])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
		],[
			AC_CHECK_HEADER([asterisk/rtp.h],
				[
					AC_DEFINE([HAVE_PBX_RTP_H],1,[Found 'asterisk/rtp.h'])
					AC_DEFINE([PBX_RTP_TYPE],[struct ast_rtp],[Defined PBX_RTP_TYPE as 'struct ast_rtp'])
					CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_rtp_new_source'...], [ac_cv_ast_rtp_new_source], [
							$HEADER_INCLUDE
							#include <asterisk/rtp.h>
						], [
							struct ast_rtp *test_rtp=NULL;
							ast_rtp_new_source(test_rtp);
						], [CS_AST_RTP_NEW_SOURCE],['ast_rtp_new_source' available]
					)

					CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_rtp_change_source'...], [ac_cv_ast_rtp_change_source], [
							$HEADER_INCLUDE
							#include <asterisk/rtp.h>
						], [
							struct ast_rtp *test_rtp=NULL;
							ast_rtp_change_source(test_rtp);
						], [CS_AST_RTP_CHANGE_SOURCE],['ast_rtp_change_source' available]
					)
				],,[ 
				#if ASTERISK_VERSION_NUMBER >= 10400
				#include <asterisk.h>
				#endif
			])
		],[ 
			#undef new
			#define new avoid_cxx_new_keyword
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/sched.h],
		[
			AC_DEFINE([HAVE_PBX_SCHED_H],1,[Found 'asterisk/sched.h'])
			AS_IF([test ${ASTERISK_VER_GROUP} -lt 110], [
				CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_sched_del'...], [ac_cv_ast_sched_del], [
						#include <unistd.h>				
						$HEADER_INCLUDE
						#ifdef HAVE_PBX_OPTIONS_H
						#  include <asterisk/options.h>
						#endif
						#ifdef HAVE_PBX_LOGGER_H
						#  include <asterisk/logger.h>
						#endif
						#include <asterisk/sched.h>
					],[
						int __attribute__((unused)) test_sched_del = AST_SCHED_DEL(NULL, 0);
					],[CS_AST_SCHED_DEL],['AST_SCHED_DEL' available]
				)
				AC_DEFINE([CS_SCHED_CONTEXT],1,[Found 'asterisk/sched.h'])
			],[
				CS_CV_TRY_COMPILE_DEFINE([ - availability 'ast_sched_del'...], [ac_cv_ast_sched_del], [
						#include <unistd.h>				
						$HEADER_INCLUDE
						#ifdef HAVE_PBX_OPTIONS_H
						#  include <asterisk/options.h>
						#endif
						#ifdef HAVE_PBX_LOGGER_H
						#  include <asterisk/logger.h>
						#endif
						#include <asterisk/sched.h>
					],[
						struct ast_sched_context *test_con = NULL;
						int __attribute__((unused)) test_sched_del = AST_SCHED_DEL(test_con, 0);
					],[CS_AST_SCHED_DEL],['AST_SCHED_DEL' available]
				)
				AC_DEFINE([CS_AST_SCHED_CONTEXT],1,[Found 'asterisk/sched.h'])
			])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/strings.h],
		[
				AC_DEFINE([HAVE_PBX_STRINGS_H],1,[Found 'asterisk/strings.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/stringfields.h],	
		[
			AC_DEFINE([HAVE_PBX_STRINGFIELDS_H],1,[Found 'asterisk/stringfields.h'])
			AC_DEFINE([CS_AST_HAS_AST_STRING_FIELD],1,[Found 'ast_string_field_' in asterisk])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/cel.h],
		[
			AC_DEFINE([HAVE_PBX_CEL_H],1,[Found 'asterisk/stringfields.h'])

			AC_MSG_CHECKING([ - availability 'ast_cel_linkedid_ref'...])
			AC_EGREP_CPP([ast_cel_linkedid_ref], [
				$HEADER_INCLUDE
				#include <asterisk/cel.h>
			],[
				AC_DEFINE([CS_AST_CEL_LINKEDID_REF],1,[Found 'ast_cel_linkedid_ref' in asterisk/cel.h])
				AC_MSG_RESULT(yes)
			],[
				AC_MSG_RESULT(no)
			])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/message.h],
		[
			AC_DEFINE([HAVE_PBX_MESSAGE_H],1,[Found 'asterisk/message.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/mwi.h],
		[
			AC_DEFINE([HAVE_PBX_MWI_H],1,[Found 'asterisk/mwi.h'])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/utils.h],
		[
			AC_DEFINE([HAVE_PBX_UTILS_H],1,[Found 'asterisk/utils.h'])

			AC_MSG_CHECKING([ - availability 'ast_free'...])
			AC_COMPILE_IFELSE([
				AC_LANG_PROGRAM(
					[
						$HEADER_INCLUDE
						#include <asterisk/utils.h>
					],[
						ast_free(NULL);
					]
				)
			],[
				
				AC_MSG_RESULT(yes)
			], [
				AC_DEFINE([ast_free],[free],['ast_free' replacement])
				AC_MSG_RESULT(no)
			])

			AC_MSG_CHECKING([ - availability 'ast_random'...])
			AC_COMPILE_IFELSE([
				AC_LANG_PROGRAM(
					[
						$HEADER_INCLUDE
						#include <asterisk/utils.h>
					], [
						unsigned int __attribute__((unused)) test_random = ast_random();
					]
				)
			], [
				AC_MSG_RESULT(yes)
			], [
				AC_DEFINE([ast_random],[random],['ast_random' replacement])
				AC_MSG_RESULT(no)
			])		
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/http.h],
		[
			AC_DEFINE([HAVE_PBX_HTTP_H],1,[Found 'asterisk/http.h'])
			HAVE_PBX_HTTP=yes
			AC_SUBST([HAVE_PBX_HTTP])
		],,[ 
			$HEADER_INCLUDE
		])
		AC_CHECK_HEADER([asterisk/backtrace.h],
		[
			AC_DEFINE([HAVE_PBX_BACKTRACE_H],1,[Found 'asterisk/backtrace.h'])
			AC_MSG_CHECKING([ - availability 'ast_bt_free_symbols'...])
			AC_EGREP_CPP([__ast_bt_free_symbols], [
				$HEADER_INCLUDE
				#include <asterisk/backtrace.h>
			],[
				AC_COMPILE_IFELSE([
					AC_LANG_PROGRAM(
						[
							$HEADER_INCLUDE
							#include <asterisk/backtrace.h>
						], [
							void	*addresses = NULL;
							size_t  size = 0;
							struct ast_vector_string *strings = __ast_bt_get_symbols(&addresses, size);
							__ast_bt_free_symbols(strings);
						]
					)
				], [
					AC_DEFINE([CS_AST_BACKTRACE_VECTOR_STRING],1,[Found 'ast_bt_free_symbols' in asterisk/backtrace.h])
					AC_DEFINE([bt_string_t],[struct ast_vector_string],[defined 'bt_string_t'])
					AC_DEFINE([bt_free],[ast_bt_free_symbols],[defined 'bt_free'])
					AC_MSG_RESULT(yes)
				], [
					AC_DEFINE([bt_string_t],[char *],[defined 'bt_string_t' replacement])
					AC_DEFINE([bt_free],[sccp_free],[defined 'bt_free' replacement])
					AC_MSG_RESULT(no)
				])		
			],[
				AC_DEFINE([bt_string_t],[char *],[defined 'bt_string_t' replacement])
				AC_DEFINE([bt_free],[sccp_free],[defined 'bt_free' replacement])
				AC_MSG_RESULT(no)
			])
		],[
			AC_DEFINE([bt_string_t],[char *],[defined 'bt_string_t' replacement])
			AC_DEFINE([bt_free],[sccp_free],[defined 'bt_free' replacement])
		],[ 
			$HEADER_INCLUDE
		])
		AS_IF([test ${MWI_USE_EVENT} -eq 1],
		[
			AC_DEFINE([MWI_USE_EVENT],1,[defined 'MWI_USE_EVENT'])
		], [
			AC_DEFINE([MWI_USE_POLLING],1,[defined 'MWI_USE_POLLING'])
		])
		dnl restore previous CFLAGS from backup
		CFLAGS={$CFLAGS_backup}
		AC_SUBST([SANITIZE_CFLAGS])
		AC_SUBST([SANITIZE_LDFLAGS])
	],[
		echo "Couldn't find asterisk/lock.h. No need to go any further. All will fail."
		echo "Asterisk version.h: ${pbx_ver/\"/}"
		echo ""
		echo "Exiting"
		exit 255
	])
])

