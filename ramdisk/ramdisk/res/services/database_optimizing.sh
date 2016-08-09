#!/sbin/busybox sh

(
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/${PROFILE}.profile;

	if [ "$cron_db_optimizing" == "on" ]; then
		for i in $(find /data -iname "*.db"); do
			/system/xbin/sqlite3 $i 'VACUUM;' > /dev/null;
			/system/xbin/sqlite3 $i 'REINDEX;' > /dev/null;
		done;

		date +%H:%M-%D > /data/crontab/cron-db-optimizing;
		echo "Done! DB was successfully Optimized." >> /data/crontab/cron-db-optimizing;
		sync;
	fi;
)&
