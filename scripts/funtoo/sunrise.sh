#!/bin/bash

sunrise_scan() {
	cd /var/lib/layman/sunrise
	for x in *; do 
		[ ! -d "$x" ] && continue
		[ "$x" = "distfiles" ] && continue
		[ "$x" = "metadata" ] && continue
		[ "$x" = "profiles" ] && continue
		for y in $x/*
		do 
			if [ -e "/usr/portage/$y" ] && [ ! -e "/usr/portage-gentoo/$y" ]
			then 
				echo $y ZAPPABLE; 
			else 
				echo $y no exists; 
			fi; 
		done
	done
}

funtoo_scan() {
	cd /usr/portage
	for x in *; do
		[ ! -d "$x" ] && continue
		[ "$x" = "distfiles" ] && continue
		[ "$x" = "metadata" ] && continue
		[ "$x" = "profiles" ] && continue
		[ "$x" = "sets" ] && continue
		[ "$x" = "packages" ] && continue
		[ "$x" = "licenses" ] && continue
		[ "$x" = "scripts" ] && continue
		for y in $x/*
		do
			if [ -e "/var/lib/layman/sunrise/$y" ]
			then
				if [ -e "/usr/portage-gentoo/$y" ]
				then
					echo "skip $y - in all trees"
				else
					if [ "`git log $y | grep sunrise`" != "" ]
					then
						echo "remove $y - sunrise git"
						continue
					else
						echo "confirm $y - possible sunrise?"
						continue
					fi
				fi
			elif [ ! -e "/usr/portage-gentoo/$y" ]
			then
				if [ -e "/usr/portage/$y/ChangeLog" ]
				then
					if [ "`cat /usr/portage/$y/ChangeLog | grep 'Tommy\[D\]'`" != "" ]
					then
						echo "remove $y - orphaned sunrise Tommy[D]"
						continue
					fi
				fi
				if [ "`git log $y | grep sunrise`" != "" ]
				then
					echo "remove $y - orphaned sunrise git"
					continue
				fi
				if [ "`git log $y | grep lavabit`" != "" ]
				then
					echo "skip $y - lavabit"
					continue
				fi
				if [ "`git log $y | grep Dantrell`" != "" ]
				then
					echo "skip $y - dantrell"
					continue
				fi
				if [ "`git log $y | grep mpd-overlay `" != "" ]
				then
					echo "skip $y - mpd"
					continue
				fi
				echo "skip $y - funtoo"
			fi
		done
	done
}
