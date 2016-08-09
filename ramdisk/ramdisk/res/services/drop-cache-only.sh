#!/sbin/busybox sh

(
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/${PROFILE}.profile;

	if [ "$cortexbrain_clean_cache" == "on" ]; then
		sleep 10800;

		MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
		MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
		MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

		# do clean cache only if cache uses 50% of free memory.
		if [ "$MEM_USED_CALC" -gt "50" ]; then
			sync;
			sleep 1;
			sysctl -w vm.drop_caches=2;
			date +%H:%M-%D > /data/.gabriel/logs/clean-ram-cache;
			echo "Cache is above 50%! Cleaned RAM Cache." >> /data/.gabriel/logs/clean-ram-cache;
		fi;
	fi;
)&
