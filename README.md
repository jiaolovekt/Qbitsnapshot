# Qbitsnapshot
Start additional qbittorrent instances from disk snapshots without manually adding torrents again(for seeding)

background&test result(still testing,may not fit for everyone,may not precise.):
![image.png](https://i.loli.net/2020/08/03/tYveVgnPKoSl7XB.png)

requires:
*    torrent stored at subdirectories in /media
*    qbittorrent installed and added to PATH
*    a few gib space for overlay file
*    user running original qbit and this script need to be the same.(read qbit configs from ~/.local)
    
usage:
```
    qbitsnapshot.sh -a <qb-cpu-affinity> -o </path-to-overlay-file> [-s <overlay-size-in-gib>] -d <source-disk-e.g.-/dev/sda3> -m <mountpoint-e.g.-/mnt/loop1> -p <qb-webui-port>
```
Script automatically restart qbit and recreate snapshot everyday for updates of new torrents.

PS: 
*    Sometimes script will report fsck and fs corrupt, that's an expected situation, just ignore and all modifications are NOT written to original disks.
*    Do NOT upload torrents to snapshoted qbit and do NOT download anything with it since all modifications are NOT written to original disks.
