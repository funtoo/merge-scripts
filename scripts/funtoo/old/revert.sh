PORTDIR=/usr/portage
cd $PORTDIR
for x in `cat $PORTDIR/profiles/funtoo-revert | grep -v '^#'`
do
	[ ! -e "$x" ] && echo "$x does not exist. exiting." && exit 1
	git rm -rf $x
	git checkout origin/funtoo.org -- $x
done

