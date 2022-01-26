#!/bin/sh
##	tswrap.sh	(c) and GPLv2 2008-2022 William Towle

SCRIPTBIN=`dirname $0`
TAGSOUP=${SCRIPTBIN}/tagsoup.sh
#[ -x ${TAGSOUP} ] || TAGSOUP=${SCRIPTBIN}/tagsoup-220125.sh

#WGET_OPT_AGENT="--user-agent=/usr/bin/firefox"
[ "${RECURSE}" ] || RECURSE=y

do_get_html_links()
{
	if [ -t 0 ] ; then
		DLOPTS=${TAGSOUP_DLOPTS} ${TAGSOUP} dumplinks ${1+"$@"}
	else
		DLOPTS=${TAGSOUP_DLOPTS} ${TAGSOUP} dumplinks -
	fi
}

do_get_inline_images()
{
	if [ -t 0 ] ; then
		DLOPTS=${TAGSOUP_DLOPTS} ${TAGSOUP} dumpimgs ${1+"$@"}
	else
		DLOPTS=${TAGSOUP_DLOPTS} ${TAGSOUP} dumpimgs -
	fi
}

do_process_url()
{
	URL=$1
	[ "${URL}" ] && shift
# reinstate pause (and write a `sleep ${PAUSE}`) to rate-limit downloads
#	PAUSE=$1
#	[ "${PAUSE}" ] && shift

	case ${URL} in
	# DEMONSTRATION: a site with links that target images
	https://ftp.gnome.org/mirror/archive/ftp.sunet.se/pub/pictures/comics/Dr-Fun/no-cartoons.html)
		do_get_html_links ${URL} | sed -n '/jpg$/ p'
	;;

	# DEMONSTRATION: a site with links that target pages
	https://www.netfunny.com/rhf/current.html)
		do_get_html_links ${URL}
	;;

#	https://dilbert.com/)
#		do_get_html_links ${URL} | sed -n '/^https:/ { /[0-9]$/ p }' | sort -u | while read SUBPAGE ; do
#			echo 'Subpage:' ${SUBPAGE}
#			[ "${RECURSE}" = 'y' ] && do_process_url ${SUBPAGE}
#		done
#			
#	;;
#	https://dilbert.com/strip/[0-9]*)
#		echo do_process_url ${SUBPAGE}
#		WGET_OPT_AGENT="--user-agent=/usr/bin/firefox" do_get_inline_images ${URL}
#	;;

	# DEMONSTRATION: xkcd's front page has latest cartoon inline
	https://xkcd.com/*)
		do_get_inline_images ${URL} | sed -n '/imgs.xkcd.com/ { /png$/ p }' | while read IMGPATH ; do
			wget -O `basename ${IMGPATH}` 'https:'${IMGPATH}
		done
	;;
	*)	echo "URL ${URL}: Unhandled pattern" 1>&2
		exit 1
	;;
	esac
#	[ "${PAUSE}" ] && sleep ${PAUSE}
}


COMMAND=$1
[ "${COMMAND}" ] && shift
case ${COMMAND} in
get-html-links)
	do_get_html_links ${1+"$@"}
;;
get-inline-images)
	do_get_inline_images ${1+"$@"}
;;
process-url)
	while [ "$1" ] ; do
		URL=$1
		shift

		do_process_url ${URL}
	done
;;
*)	if [ -n "${COMMAND}" -a "${COMMAND}" != 'help' ] ; then
		echo "$0: Unrecognised command '${COMMAND}'"
	fi
	echo "$0: Usage:"
	grep "^[0-9a-z-]*)" $0 | sed "s/^/	/"
	exit 1
;;
esac
