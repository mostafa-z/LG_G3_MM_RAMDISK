#!/sbin/busybox sh

BB=/sbin/busybox

SYSTEM=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/userdata | $BB grep "f2fs" | $BB wc -l);

if [ "${SYSTEM}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/userdata /data;
else
	$BB mount -t ext4 -o nosuid nodev noatime barrier=1 data=journal noauto_da_alloc errors=panic /dev/block/platform/msm_sdcc.1/by-name/userdata /data;
fi;
