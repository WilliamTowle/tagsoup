#!/bin/sh
##	tagsoup		(c) and GPLv2 2008-2009 William Towle
##	Last modified	2009-01-13, WmT
##	Purpose		web page dissection
#
#*   Open Source software - copyright and GPLv2 apply. Briefly:       *
#*    - No warranty/guarantee of fitness, use is at own risk          *
#*    - No restrictions on strictly-private use/copying/modification  *
#*    - No re-licensing this work under more restrictive terms        *
#*    - Redistributing? Include/offer to deliver original source      *
#*   Philosophy/full details at http://www.gnu.org/copyleft/gpl.html  *

##QUOTE_REGEX="[\'\"]"
#WGET_OPT_AGENT="--user-agent=$0"

get()
{
	if [ -z "$1" ] ; then
		echo "$0: test(): No SOURCE[s]" 1>&2
		exit 1
	fi

	while [ "$1" ] ; do
		SOURCE=$1
		shift

		DLOPTS=''
# EDIT HERE: set DLOPTS for any sites that need a particular user-agent
#		case ${SOURCE} in
#		http://*.DOMAIN.com/PATH/*)
#			DLOPTS="${WGET_OPT_AGENT}"
#		esac

		case ${SOURCE} in
		[a-z]*://*)
			wget ${DLOPTS} -q -O - ${SOURCE}
		;;
		*)
			cat ${SOURCE}
		;;
		esac
	done
}

separate()
{	## from 'relay.sh' 26/12/2008 - readjust multi-line layout

	awk	'
	BEGIN { IRS= "\n" ; ORS= ""
		unparsed= "" }
	{
		if (unparsed)
		{
			unparsed = unparsed " " $0
		}
		else
		{
			unparsed = $0
		}

		do
		{
			inp_ob= index(unparsed, "<")
			inp_cb= index(unparsed, ">")
			repeat= 0

			if ( inp_cb && ((inp_ob == 0) || (inp_cb < inp_ob)) )
			{
				if (inp_ob == 0)
				{
					print unparsed "\n"
					unparsed= ""
				}
				else ## inp_cb < inp_ob
				{
					print substr(unparsed, inp_ob) "\n"
					unparsed= substr(unparsed, inp_ob)
					repeat= 1
				}
			}
			else if ( inp_ob < inp_cb)
			{
				## leading text?
				if (inp_ob > 1)
				{
					print substr(unparsed, 1, inp_ob-1) "\n"
					unparsed= substr(unparsed, inp_ob)
				}

				print substr(unparsed, 1, inp_cb-inp_ob+1) "\n"
				unparsed= substr(unparsed, inp_cb-inp_ob+2)
				repeat= 1
			}
			else if ((inp_ob == 0) && unparsed)
			{	## some plain text
				print unparsed "\n"
				unparsed= ""
			}
#			## else -> multi-line tag
#			else
#			{
#print "...unhandled (ob " inp_ob " cb " inp_cb "..." unparsed ")\n"
#			}
		}
		while (repeat)
	}
	END { if (unparsed) { print "..." unparsed "\n" } }	# spew any unhandled text
	'
}

tag_grep()
{
	separate | grep -i '< *'${1}' *'
}

showattr()
{
	export ATTR="$1"

	awk '	BEGIN {	IGNORECASE= 1; attr=ENVIRON["ATTR"] }

		{	low= tolower($0);

			# should be one tag per line
			# but dont assume one attribute per tag
			while (attpos= index(low, attr))
			{
			    q1pos= attpos + length(attr);
			    while (substr(low,q1pos) ~ /^[ =]/) q1pos++
			    soq= substr(low, q1pos, 1)
			    q2pos= q1pos + index(substr(low,q1pos+1),soq)
			    print substr($0, q1pos+1, q2pos - q1pos - 1)
			    low= substr(low, q2pos+1)
			    $0= substr($0, q2pos+1)
			}
		}
		'
}

get_ahref()
{
	tag_grep 'a' | showattr 'href'
}

get_imgsrc()
{
	tag_grep 'img' | showattr 'src'
}

dumplinks()
{
	URL="$1"

	case ${URL} in
# EDIT HERE: handle any sites for which output needs to be filtered
#	http://*.DOMAIN.com/PATH/*)
#		get ${URL} | get_ahref | sed "s/^[^']*'// ; s/'.*//"
#	;;
	*)
		get ${URL} | get_ahref
	;;
	esac
}

dumpimgs()
{
	URL="$1"

	case ${URL} in
# EDIT HERE: handle any sites for which output needs to be filtered
#	http://*.DOMAIN.com/PATH/*)
#		get ${URL} | get_ahref | sed "s/^[^']*'// ; s/'.*//"
#	;;
	*)
		get ${URL} | get_imgsrc
	;;
	esac
}

ACTION=$1
[ "$1" ] && shift
case ${ACTION} in
get)		## retrieve page/file
	get $*
;;
separate)	## 'get' with layout readjustment, one tag per line
	get $* | separate
;;
ahref)		## 'separate', filter anchor tags, show href=
	get $* | get_ahref
;;
imgsrc)		## 'separate', filter img tags, show src=
	get $* | get_imgsrc
;;
dumplinks)	## site-sensitive 'ahref' filtering
	dumplinks $*
;;
dumpimgs)	## site-sensitive 'imgsrc' filtering
	dumpimgs $*
;;
*)
	if [ -n "${ACTION}" -a "${ACTION}" != 'help' ] ; then
		echo "$0: Unrecognised command '${ACTION}'"
	fi
	echo "$0: Usage:"
	grep "^[0-9a-z-]*)" $0 | sed "s/^/	/"
	exit 1
;;
esac
