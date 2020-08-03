# Qbitsnapshot
Start additional qbittorrent instances from disk snapshots without manually adding torrents again(for seeding)

background&test result(may not fit for everyone):
![image.png](https://i.loli.net/2020/08/03/X275ZxYwan9TWlC.png)

requires:
    torrent stored at subdirectories in /media
    qbittorrent installed and added to PATH
    a few gib space for overlay file
    
usage:
    usage qbitsnapshot.sh -a <qb-cpu-affinity> -o </path-to-overlay-file> [-s <overlay-size-in-gib>] -d <source-disk-e.g.-/dev/sda3> -m <mountpoint-e.g.-/mnt/loop1> -p <qb-webui-port>
