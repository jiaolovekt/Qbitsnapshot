#!/bin/bash
#usage qbitsnapshot.sh -a <affinity> -o </overlay-path> [-s <overlay size in gib>] -d </dev/sda3> -m </mnt/loop1> -p <webui-port>
set -e
#set -x

init_var()
{
Qaffinity=
Qoverlayname="/Qoverlay$$"
Qoverlayfile=
Qoverlaypath=
Qoverlaysize=8
Qsrcdisk=
Qmountpoint=
Qsrcloop=
Qoverlayloop=
Qmapperdev=qb$$
Qport=1234
Qrestartduration=86400	# modify if needed
Qseedingdir=/media		# modify if needed
countA=1
}
callexit()
{
echo SIG received
cleanup
exit 0
}

Qhelp()
{
echo "usage qbitsnapshot.sh -a <affinity> -o </overlay-path> [-s <overlay size in gib>] -d </dev/sda3> -m </mnt/loop1> -p <webui-port>" 
}

init_loops()
{
Qoverlayfile="$Qoverlaypath"$Qoverlayname
Qsrcloop=`losetup -r -f --show "$Qsrcdisk"` 
truncate -s "$Qoverlaysize"G "$Qoverlayfile" 
Qoverlayloop=`losetup -f --show "$Qoverlayfile"` 
echo "source disk is $Qsrcdisk , source loop device is $Qsrcloop , overlay device is $Qoverlayloop ."
trap "cleanup" TERM
}

init_snapshot()
{
read -r -n 1 -t 5 -p "setting dmsetup in 5 seconds" || true
if dmsetup create $Qmapperdev --table "0 `blockdev --getsize $Qsrcdisk` snapshot $Qsrcloop $Qoverlayloop P 8" ; then
	echo -e "\ndmsetup success, mapper dev is $Qmapperdev"
else
	echo dmsetup failed.
	exit 6
fi
}

fscknmount()
{
[ -d "$Qmountpoint" ] || mkdir -p $Qmountpoint
sync
if mount /dev/mapper/$Qmapperdev $Qmountpoint ; then
	echo mount snapshot success;
else
	echo mount $Qmapperdev failed. maybe need fsck.
	sync
	fsck.ext4 -y /dev/mapper/$Qmapperdev || true
	sync
	if mount /dev/mapper/$Qmapperdev $Qmountpoint ; then
		echo mount success after fsck.
	else
		echo mount failed.
		exit 7
	fi
fi
mount --bind /dev $Qmountpoint/dev
mount -t proc proc $Qmountpoint/proc
mount -t sysfs sys $Qmountpoint/sys
mount --bind -o ro $Qseedingdir $Qmountpoint$Qseedingdir	
mount --bind -o ro /media/cdrom0 $Qmountpoint/media/cdrom0	
mount --bind -o ro /media/cdrom1 $Qmountpoint/media/cdrom1	
}

startqbit()
{
read -r -n 1 -t 5 -p "Starting Qbit affinity $Qaffinity at port $Qport in 5 sec" || true
date
trap "callexit" QUIT
chroot $Qmountpoint taskset $Qaffinity timeout -s 2 -k 600 $Qrestartduration qbittorrent-nox --webui-port=$Qport &
Qpid=$!
echo Qbit runnning at $Qpid
wait $Qpid
}

cleanup()
{
[-n $Qpid] && kill -9 $Qpid
echo umount $Qmountpoint
umount $Qmountpoint/* || true
umount -R $Qmountpoint || true
echo removing $Qmapperdev
dmsetup remove $Qmapperdev || echo no $Qmapperdev
echo removing $Qsrcloop $Qoverlayloop
losetup -d $Qsrcloop
losetup -d $Qoverlayloop
echo removing overlay file
rm -f $Qoverlayfile
echo cleanup done.
}

init_var
while getopts "a:o:s:d:m:p:h" opt
do 
	case $opt in
		a)
		Qaffinity="$OPTARG"
		;;
		o)
		Qoverlaypath="$OPTARG"
		;;
		s)
		Qoverlaysize="$OPTARG"
		;;
		d)
		Qsrcdisk="$OPTARG"
		;;
		m)
		Qmountpoint="$OPTARG"
		;;
		p)
		Qport="$OPTARG"
		;;
		h)
		Qhelp
		exit 0
		;;
		\?)
		exit 1
		;;
	esac
done
if [ -z "$Qaffinity" ] ; then
	echo "Affinity not set!"
	exit 2
fi
if [ -z "$Qoverlaypath" ] ; then
	echo "Overlay path not set!"
	exit 3
fi
if [ -z "Qsrcdisk" ] ; then
	echo "Src disk not set!"
	exit 4
fi
if [ -z "Qmountpoint" ] ; then
	echo "Mountpoint not set!"
	exit 5
fi

while true ; do
	init_loops
	init_snapshot
	fscknmount
	startqbit
	cleanup
	sleep 10
	sync
	sync
	sync
done
