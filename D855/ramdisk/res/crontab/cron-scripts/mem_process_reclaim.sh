#!/sbin/busybox sh
# memory process reclaim script, made by Dorimanx

(
	if [ ! -f /system/xbin/su ]; then
		exit 1;
	fi;

		for i in $(ls /proc/ | grep -E '^[0-9]+'); do
			if [ "$i" -ge "1500" ] && [ -f /proc/$i/reclaim ]; then
				su -c echo "3" > /proc/$i/reclaim;
			fi;
		done;
		date +%H:%M-%D > /data/crontab/cron-mem_process_reclaim;
		echo "Done! Ram Reclaimed" >> /data/crontab/cron-mem_process_reclaim;
)&
