#!/bin/bash

# this file is only used for development testing. Do not use for anything else.

sudo rsync -aAX --numeric-ids \
  --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
  / /mnt/backup/rootfs
