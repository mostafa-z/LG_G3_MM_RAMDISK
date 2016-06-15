#!/sbin/busybox sh

(
		for i in $(find /data -iname "*.db"); do
			/system/xbin/sqlite3 $i 'VACUUM;' > /dev/null;
			/system/xbin/sqlite3 $i 'REINDEX;' > /dev/null;
		done;

		date +%H:%M-%D > /data/crontab/cron-db-optimizing;
		echo "Done! DB Optimized" >> /data/crontab/cron-db-optimizing;
		sync;
)&
