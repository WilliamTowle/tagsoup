#!/bin/sh
##	relay		(c) and GPLv2 2008-2011 William Towle
##	Last modified	2013-04-25, WmT
##	Purpose		web page dissection
#
#*   Open Source software - copyright and GPLv2 apply. Briefly:       *
#*    - No warranty/guarantee of fitness, use is at own risk          *
#*    - No restrictions on strictly-private use/copying/modification  *
#*    - No re-licensing this work under more restrictive terms        *
#*    - Redistributing? Include/offer to deliver original source      *
#*   Philosophy/full details at http://www.gnu.org/copyleft/gpl.html  *

##QUOTE_REGEX="[\'\"]"
WGET_OPT_AGENT="--user-agent=$0"

get()
{
	if [ -z "$1" ] ; then
		echo "$0: test(): No SOURCE[s]" 1>&2
		exit 1
	fi

	while [ "$1" ] ; do
		SOURCE=$1
		shift

		if [ "${TAGSOUP_DLOPTS}" ] ; then
			DLOPTS=${TAGSOUP_DLOPTS}
		else
			DLOPTS=''
		fi
		# TODO: force DLOPTS="${WGET_OPT_AGENT}" if appropriate

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

relay()
{	## readjust multi-line layout
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
	relay | grep -i '< *'${1}' *'
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

ACTION=$1
[ "$1" ] && shift
case ${ACTION} in
get)		## simple page/file retrieval
	get $*
;;
relay)		## 'get' with one tag per line readjustment
	get $* | relay
;;
ahref)		## 'relay', filter anchor tags, show href=
	get $* | get_ahref
;;
imgsrc)		## 'relay', filter img tags, show src=
	get $* | get_imgsrc
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
