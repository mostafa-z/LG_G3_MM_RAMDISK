#!/sbin/busybox sh
# memory process reclaim script, made by Dorimanx

(
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/${PROFILE}.profile;

	if [ ! -f /system/xbin/su ]; then
		exit 1;
	fi;

	if [ "$cortexbrain_process_reclaim" == "on" ]; then
		sleep 10800;
		for i in $(ls /proc/ | grep -E '^[0-9]+'); do
			if [ "$i" -ge "1500" ] && [ -f /proc/$i/reclaim ]; then
				su -c echo "all" > /proc/$i/reclaim;
			fi;
		done;
		date +%H:%M-%D > /data/.gabriel/logs/mem-process-reclaim;
		echo "Done! Ram Reclaimed." >> /data/.gabriel/logs/mem-process-reclaim;
	fi;
)&
