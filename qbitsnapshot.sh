#!/bin/bash
#usage qbitsnapshot.sh -a <affinity> -d </tempdir-not-in-"/"> [-t <time-before-restart>] [-s </seeding/dir>] -m </mountpoint> -p <webui-port>
#set -e
#set -x
#TODO: multiple instance need to be terminated and restarted
init_var()
{
Qaffinity=
Qoverlaydir=
Qmountpoint=
Qsrcloop=
Qoverlayloop=
Qport=1234
Qrestartduration=86400	
Qseedingdir=/media		
Qusingtmpfs=1	#modify if needed
}


Qhelp()
{
echo "qbitsnapshot.sh -a <affinity> -d </tempdir-not-in-"/"> [-t <time-before-restart>] [-s </seeding/dir>] -m </mountpoint> -p <webui-port>" 
}

init_tmpfs()
{
echo initing tmpfs
[ -d "$Qoverlaydir" ] || mkdir -p "$Qoverlaydir"
mount -t tmpfs -o size=4G tmpfs "$Qoverlaydir"
}

init_overlay()
{
[ $Qusingtmpfs = 1 ] && init_tmpfs
Qoverlaylower="$Qoverlaydir/Qlo$$"
Qoverlayupper="$Qoverlaydir/Qup$$"
Qoverlaywd="$Qoverlaydir/Qwd$$"
mkdir $Qoverlaylower
mkdir $Qoverlayupper
mkdir $Qoverlaywd
trap "callexit=1 && cleanup" TERM
echo setting up ro sourcemount in 5 sec && sleep 5
mount --bind --make-private -o ro / "$Qoverlaylower"
echo setting up overlay in 3 sec && sleep 3
if mount -t overlay overlay -o upperdir="$Qoverlayupper",lowerdir="$Qoverlaylower",workdir="$Qoverlaywd" "$Qmountpoint"; then
	echo overlay success
else
	echo mount failed, check temp dir should NOT in mountpoint /.
	cleanup
	exit 6
fi
mount --bind /dev "$Qmountpoint"/dev
mount -t proc proc "$Qmountpoint"/proc
mount -t sysfs sys "$Qmountpoint"/sys
mount --bind -o ro "$Qseedingdir" "$Qmountpoint""$Qseedingdir"	
mount --bind -o ro /media/cdrom0 $Qmountpoint/media/cdrom0	# for test
mount --bind -o ro /media/cdrom1 $Qmountpoint/media/cdrom1	# for test
}

startqbit()
{
read -r -n 1 -t 5 -p "Starting Qbit affinity $Qaffinity at port $Qport in 5 sec" || true
date
chroot "$Qmountpoint" taskset $Qaffinity timeout -s 2 -k 600 $Qrestartduration qbittorrent-nox --webui-port=$Qport & true
Cpid=$! && Qpid=$((Cpid+1))
echo chroot runnning at $Cpid Qbit running at $((Cpid+1))
wait $Cpid
}

cleanup()
{
[ -n "$Qpid" ] && kill -9 $Qpid
echo try unmounting overlay.
if umount -R "$Qmountpoint" ; then
	echo umount success.
else
	echo umount failed, maybe Qbit still runnning
	Qpid=`ps aux | grep qbit | grep $Qport | awk -F ' ' '{print $2}'`
	if [ -z "$Qpid" ] ; then
		echo qpid not found.
		umount -R "$Qmountpoint"
	else
		echo killing Qbit runnning at $Qpid
		kill -9 $Qpid
		umount -R "$Qmountpoint"
	fi
fi
echo umount ro sourcemount
umount -R "$Qmountpoint"
umount -R "$Qmountpoint"
umount -R "$Qmountpoint"
umount -R $Qoverlaylower
umount -R $Qoverlaylower
umount -R $Qoverlaylower
[ "$Qusingtmpfs" = 1 ] && umount -R $Qoverlaydir
echo cleaning temp dir
sleep 5
[ "$Qoverlaydir" != "/" ] && rm -rf "$Qoverlaydir"
echo cleanup done.
[ "$callexit" = "1"] && echo SIGTERM received && exit 0
}

callrestart()
{

}

calledrestart()
{

}
init_var
while getopts "a:d:t:s:m:p:h" opt
do 
	case $opt in
		a)
		Qaffinity="$OPTARG"
		;;
		d)
		Qoverlaydir="$OPTARG"
		;;
		t)
		Qrestartduration="$OPTARG"
		;;
		s)
		Qseedingdir="$OPTARG"
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
if [ -z "$Qoverlaydir" ] ; then
	echo "Overlay Upath not set!"
	exit 3
fi
if [ -z "Qmountpoint" ] ; then
	echo "Mountpoint not set!"
	exit 4
fi

while true ; do
	init_overlay
	startqbit
	cleanup
	sleep 10
	sync
	sync
	sync
done
