#!/bin/sh
redis-server /mnt/redis/etc/rd_default.conf
cd /mnt/server/ss-py-mu/shadowsocks &&  python server.py >> /mnt/logs/sspy.log 2>&1
