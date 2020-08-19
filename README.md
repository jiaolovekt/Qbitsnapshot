# Qbitsnapshot
Start additional qbittorrent instances from disk snapshots without manually adding torrents again(for seeding).

background&test result(still testing,may not fit for everyone,may not precise.):
![image.png](https://i.loli.net/2020/08/03/tYveVgnPKoSl7XB.png)
from 2x Hetzner 32G 3TBx2
seeding seems improved when running more processes

requires:
*    qbittorrent installed and added to PATH
*    a few gib space for overlay files (or tmpfs)
*    user running original qbit and this script need to be the same.(read qbit configs from ~/.local)
    
usage:
```
    qbitsnapshot.sh -a <affinity> -d </tempdir-not-in-"/"> [-t <time-before-restart>] [-s </seeding/dir>] -m </mountpoint> -p <webui-port>
```
Script automatically restart qbit and recreate snapshot everyday to avoid OOM

PS: 
*    Do NOT upload torrents to snapshoted qbit and do NOT download anything with it since all modifications are NOT written to original disks.
*	 If using qbittorrent's auto add torrent the snapshot instances will add and hash new torrents automatically now.
