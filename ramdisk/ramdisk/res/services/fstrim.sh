#!/sbin/busybox sh

(
	BB=/sbin/busybox
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/${PROFILE}.profile;

	if [ "$cortexbrain_trim" == "on" ]; then

	# calculate the remaining seconds to 10 PM
	HTIME=$(date +%H:%M | cut -c 1-2);
	HTIME=$((22-$HTIME));
	HTIME=$(($HTIME*3600));
	MTIME=$(date +%H:%M | cut -c 4-5);
	MTIME=$((60-$MTIME));
	MTIME=$(($MTIME*60));
	RTIME=$(($HTIME+$MTIME));

	# change mode for /tmp/
	ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
	if [ "$ROOTFS_MOUNT" -eq "0" ]; then
		mount -o remount,rw /;
	fi;
	chmod -R 777 /tmp/;



	if [ "$cron_fstrim" == "on" ]; then
		SCREEN_WAS_OFF=0;
		SYSTEM_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/system | $BB grep "f2fs" | $BB wc -l)
		DATA_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/data | $BB grep "f2fs" | $BB wc -l)
		CACHE_CHECK=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/cache | $BB grep "f2fs" | $BB wc -l)

		if [ "$SYSTEM_CHECK" -eq "0" ] || [ "$DATA_CHECK" -eq "0" ] || [ "$CACHE_CHECK" -eq "0" ]; then
			if [ "$(dumpsys power | grep mWakefulness= | grep -oE '(Awake|Asleep)')" == "Asleep" ] ; then
				input keyevent 26 # wakeup
				SCREEN_WAS_OFF=1;
			fi;
		fi;

		sleep $RTIME;

		if [ "$SYSTEM_CHECK" -eq "0" ]; then
			$BB fstrim /system
		fi;
		if [ "$DATA_CHECK" -eq "0" ]; then
			$BB fstrim /data
		fi;
		if [ "$CACHE_CHECK" -eq "0" ]; then
			$BB fstrim /cache
		fi;
		date +%H:%M-%D > /data/.gabriel/logs/cortex-fstrim;
		echo "FS Trimmed." >> /data/.gabriel/logs/cortex-fstrim;
		sync;
		if [ "$SCREEN_WAS_OFF" -eq "1" ]; then
			if [ "$(dumpsys power | grep mWakefulness= | grep -oE '(Awake|Asleep)')" == "Awake" ] ; then
				input keyevent 26 # sleep
			fi;
		fi;
	fi;
	fi;
)&
