for cat in /usr/portage/*
do
for pkg in $cat/*
do
if [ -d $pkg ]
then
if [ ! -f $pkg/metadata.xml ]
then
echo "Missing for $pkg"
fi
fi
done
done

