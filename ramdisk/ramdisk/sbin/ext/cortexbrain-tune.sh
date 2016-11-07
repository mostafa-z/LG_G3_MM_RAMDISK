#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

BB=/sbin/busybox

# change mode for /tmp/
ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	mount -o remount,rw /;
fi;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
# (since we don't have the recovery source code I can't change the ".gabriel" dir, so just leave it there for history)
DATA_DIR=/data/.gabriel;

# ==============================================================
# INITIATE
# ==============================================================

# For CHARGER CHECK.
echo "1" > /data/gabriel_cortex_sleep;

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS_STATE=1;
else
	DUMPSYS_STATE=0;
fi;

# ==============================================================
# FILES FOR VARIABLES || we need this for write variables from child-processes to parent
# ==============================================================

# WIFI HELPER
WIFI_HELPER_AWAKE="$DATA_DIR/WIFI_HELPER_AWAKE";
WIFI_HELPER_TMP="$DATA_DIR/WIFI_HELPER_TMP";
echo "1" > $WIFI_HELPER_TMP;

# MOBILE HELPER
MOBILE_HELPER_AWAKE="$DATA_DIR/MOBILE_HELPER_AWAKE";
MOBILE_HELPER_TMP="$DATA_DIR/MOBILE_HELPER_TMP";
echo "1" > $MOBILE_HELPER_TMP;

# CLEAN CACHE HELPER
CLEAN_CACHE_TIMEOUT_HELPER="$DATA_DIR/CLEAN_CACHE_TIMEOUT_HELPER";
CLEAN_CACHE_HELPER_TMP="$DATA_DIR/CLEAN_CACHE_HELPER_TMP";
echo "0" > $CLEAN_CACHE_HELPER_TMP;

# PROCESS RECLAIM HELPER
PROCESS_RECLAIM_TIMEOUT_HELPER="$DATA_DIR/PROCESS_RECLAIM_TIMEOUT_HELPER";
PROCESS_RECLAIM_HELPER_TMP="$DATA_DIR/PROCESS_RECLAIM_HELPER_TMP";
echo "0" > $PROCESS_RECLAIM_HELPER_TMP;

# FSTRIM HELPER
FSTRIM_TIMEOUT_HELPER="$DATA_DIR/FSTRIM_TIMEOUT_HELPER";
FSTRIM_HELPER_TMP="$DATA_DIR/FSTRIM_HELPER_TMP";
echo "0" > $FSTRIM_HELPER_TMP;

# APP CACHE HELPER
APPCACHE_TIMEOUT_HELPER="$DATA_DIR/APPCACHE_TIMEOUT_HELPER";
APPCACHE_HELPER_TMP="$DATA_DIR/APPCACHE_HELPER_TMP";
echo "0" > $APPCACHE_HELPER_TMP;

# DP OPTIMIZATION HELPER
DP_OPT_TIMEOUT_HELPER="$DATA_DIR/DP_OPT_TIMEOUT_HELPER";
DP_OPT_HELPER_TMP="$DATA_DIR/DP_OPT_HELPER_TMP";
echo "0" > $DP_OPT_HELPER_TMP;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local i="";

		local MMC=$(find /sys/block/mmc*);
		for i in $MMC; do
			echo "$scheduler" > "$i"/queue/scheduler;
			echo "0" > "$i"/queue/rotational;
			echo "0" > "$i"/queue/iostats;
			echo "2" > "$i"/queue/nomerges;
		done;

		# This controls how many requests may be allocated
		# in the block layer for read or write requests.
		# Note that the total allocated number may be twice
		# this amount, since it applies only to reads or writes
		# (not the accumulated sum).
		echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

		# our storage is 16/32GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "$read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;
		echo "$read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t "$FILE_NAME" "*** IO_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == "on" ]; then
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;
		echo "0" > /proc/sys/kernel/panic_on_oops;

		log -p i -t "$FILE_NAME" "*** KERNEL_TWEAKS ***: enabled";
	else
		echo "kernel_tweaks disabled";
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == "on" ]; then
		setprop windowsmgr.max_events_per_sec 240;

		log -p i -t "$FILE_NAME" "*** SYSTEM_TWEAKS ***: enabled";
	else
		echo "system_tweaks disabled";
	fi;
}
SYSTEM_TWEAKS;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 20
		echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 25
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "8192" > /proc/sys/vm/min_free_kbytes; #default: 2572
		# mem calc here in pages. so 16384 x 4 = 64MB reserved for fast access by kernel and VM
		echo "32768" > /proc/sys/vm/mmap_min_addr; #default: 32768

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
MEMORY_TWEAKS;

BATTERY_TWEAKS()
{
	if [ "$cortexbrain_battery" == "on" ]; then
		# battery-calibration if battery is full
		local LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		local CURR_ADC=`cat /sys/class/power_supply/battery/voltage_now`;
		local BATTFULL=`cat /sys/class/power_supply/battery/status`;
		local i="";
		local bus="";

		log -p i -t $FILE_NAME "*** BATTERY - LEVEL: $LEVEL - CUR: $CURR_ADC ***";

		if [ "$LEVEL" -eq "100" ] && [ "$BATTFULL" == "Full" ]; then
			rm -f /data/system/batterystats.bin;
			log -p i -t $FILE_NAME "battery-calibration done ...";
		fi;

		log -p i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}

WIFI_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		service call wifi 13 i32 0 > /dev/null;
		svc wifi disable;
		echo "1" > $WIFI_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		service call wifi 13 i32 1 > /dev/null;
		svc wifi enable;
	fi;

	log -p i -t $FILE_NAME "*** WIFI ***: $state";
}

WIFI()
{
	local state="$1";

	if [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" -eq "0" ]; then
				WIFI_SET "off";
			else
				(
					echo "0" > $WIFI_HELPER_TMP;
					# screen time out but user want to keep it on and have wifi
					sleep 10;
					if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
						# user did not turned screen on, so keep waiting
						local SLEEP_TIME_WIFI=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
						log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
						sleep $SLEEP_TIME_WIFI;
						if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
							# user left the screen off, then disable wifi
							WIFI_SET "off";
						fi;
					fi;
				)&
			fi;
		else
			# i don't want wifi status changes in awake mode if auto_tweak is off
			echo "0" > $WIFI_HELPER_AWAKE;
		fi;
	elif [ "$state" == "awake" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			echo "1" > $WIFI_HELPER_TMP;
			if [ `cat $WIFI_HELPER_AWAKE` -eq "1" ]; then
				WIFI_SET "on";
			fi;
		fi;
	fi;
}

MOBILE_DATA_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		svc data disable;
		echo "1" > $MOBILE_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		svc data enable;
	fi;

	log -p i -t $FILE_NAME "*** MOBILE DATA ***: $state";
}

MOBILE_DATA_STATE()
{
	DATA_STATE_CHECK=0;

	if [ $DUMPSYS_STATE -eq "1" ]; then
		local DATA_STATE=`echo "$TELE_DATA" | awk '/mDataConnectionState/ {print $1}'`;

		if [ "$DATA_STATE" != "mDataConnectionState=0" ]; then
			DATA_STATE_CHECK=1;
		fi;
	fi;
}

MOBILE_DATA()
{
	local state="$1";

	if [ "$cortexbrain_auto_tweak_mobile" == "on" ]; then
		if [ "$state" == "sleep" ]; then
			MOBILE_DATA_STATE;
			if [ "$DATA_STATE_CHECK" -eq "1" ]; then
				if [ "$cortexbrain_auto_tweak_mobile_sleep_delay" -eq "0" ]; then
					MOBILE_DATA_SET "off";
				else
					(
						echo "0" > $MOBILE_HELPER_TMP;
						# screen time out but user want to keep it on and have mobile data
						sleep 10;
						if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							local SLEEP_TIME_DATA=$(( $cortexbrain_auto_tweak_mobile_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_MOBILE $cortexbrain_auto_tweak_mobile_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_DATA;
							if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable mobile data
								MOBILE_DATA_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $MOBILE_HELPER_AWAKE;
			fi;
		elif [ "$state" == "awake" ]; then
			echo "1" > $MOBILE_HELPER_TMP;
			if [ `cat $MOBILE_HELPER_AWAKE` -eq "1" ]; then
				MOBILE_DATA_SET "on";
			fi;
		fi;
	fi;
}

VFS_CACHE_PRESSURE()
{
	local state="$1";
	local sys_vfs_cache="/proc/sys/vm/vfs_cache_pressure";

	if [ -e $sys_vfs_cache ]; then
		if [ "$state" == "awake" ]; then
			echo "$vfs_cache_pressure" > $sys_vfs_cache;
		elif [ "$state" == "sleep" ]; then
			echo "$vfs_cache_pressure_sleep" > $sys_vfs_cache;
		fi;

		log -p i -t $FILE_NAME "*** VFS_CACHE_PRESSURE: $state ***";

		return 0;
	fi;

	return 1;
}

SWAPPINESS()
{
	local state="$1";
	local sys_swappiness="/proc/sys/vm/swappiness";

	if [ -e $sys_swappiness ]; then
		if [ "$state" == "awake" ]; then
			echo "$swappiness" > $sys_swappiness;
		elif [ "$state" == "sleep" ]; then
			echo "$swappiness_sleep" > $sys_swappiness;
		fi;

		log -p i -t $FILE_NAME "*** SWAPPINESS: $state ***";

		return 0;
	fi;

	return 1;
}

NET()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes; # default: 3
		echo "1200" > /proc/sys/net/ipv4/tcp_keepalive_time; # default: 7200s
		echo "10" > /proc/sys/net/ipv4/tcp_keepalive_intvl; # default: 75s
		echo "10" > /proc/sys/net/ipv4/tcp_retries2; # default: 15
	elif [ "$state" == "sleep" ]; then
		echo "2" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "300" > /proc/sys/net/ipv4/tcp_keepalive_time;
		echo "5" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "5" > /proc/sys/net/ipv4/tcp_retries2;
	fi;

	log -p i -t $FILE_NAME "*** NET ***: $state";
}

# ==============================================================
# OOM-TUNING
# protect services from oom and doing at every state check
# use -1000 & oom_score_adj for kernel 3.x
# ==============================================================

CLEAN_CACHE()
{	
	if [ "$cortexbrain_clean_cache" == "on" ]; then
		if [ "$(pgrep -f drop_cache_only | wc -l)" -eq "0" ]; then
			if [ "$cortexbrain_clean_cache_timeout" != "3" ]; then
				echo $cortexbrain_clean_cache_timeout > $CLEAN_CACHE_TIMEOUT_HELPER;
				$BB nohup $BB sh /res/services/drop_cache_only $cortexbrain_clean_cache_timeout > /data/.gabriel/logs/clean_cache &
				pgrep -f "/res/services/drop_cache_only" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING CLEAN CACHE ***";
			else
				$BB nohup $BB sh /res/services/drop_cache_only > /data/.gabriel/logs/clean_cache &
				pgrep -f "/res/services/drop_cache_only" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING CLEAN CACHE ***";
			fi;
		else
			if [ "$cortexbrain_clean_cache_timeout" != "3" ]; then
				echo $cortexbrain_clean_cache_timeout > $CLEAN_CACHE_HELPER_TMP;
					if [ `cat $CLEAN_CACHE_TIMEOUT_HELPER` != `cat $CLEAN_CACHE_HELPER_TMP` ]; then
						pkill -f "drop_cache_only";
						$BB nohup $BB sh /res/services/drop_cache_only $cortexbrain_clean_cache_timeout > /data/.gabriel/logs/clean_cache &
						pgrep -f "/res/services/drop_cache_only" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
						echo $cortexbrain_clean_cache_timeout > $CLEAN_CACHE_TIMEOUT_HELPER;
						log -p i -t "$FILE_NAME" "*** RUNNING CLEAN CACHE ***";
					fi;
			else
				log -p i -t "$FILE_NAME" "*** CLEAN CACHE ALREADY RUNNING WITH DEFAULT TIME PERIOD ***";
			fi;
		fi;

	else
		pkill -f "drop_cache_only";	
		log -p i -t "$FILE_NAME" "*** CLEAN CACHE IS OFF ***";
	fi;
}

PROCESS_RECLAIM()
{	
	if [ "$cortexbrain_process_reclaim" == "on" ]; then
		if [ "$(pgrep -f mem_process_reclaim | wc -l)" -eq "0" ]; then
			if [ "$cortexbrain_process_reclaim_timeout" != "3" ]; then
				echo $cortexbrain_process_reclaim_timeout > $PROCESS_RECLAIM_TIMEOUT_HELPER;
				$BB nohup $BB sh /res/services/mem_process_reclaim $cortexbrain_process_reclaim_timeout > /data/.gabriel/logs/process_reclaim &
				pgrep -f "/res/services/mem_process_reclaim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING PROCESS RECLAIM ***";
			else
				$BB nohup $BB sh /res/services/mem_process_reclaim > /data/.gabriel/logs/process_reclaim &
				pgrep -f "/res/services/mem_process_reclaim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING PROCESS RECLAIM ***";
			fi;
		else
			if [ "$cortexbrain_process_reclaim_timeout" != "3" ]; then
				echo $cortexbrain_process_reclaim_timeout > $PROCESS_RECLAIM_HELPER_TMP;
					if [ `cat $PROCESS_RECLAIM_TIMEOUT_HELPER` != `cat $PROCESS_RECLAIM_HELPER_TMP` ]; then
						pkill -f "mem_process_reclaim";
						$BB nohup $BB sh /res/services/mem_process_reclaim $cortexbrain_process_reclaim_timeout > /data/.gabriel/logs/process_reclaim &
						pgrep -f "/res/services/mem_process_reclaim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
						echo $cortexbrain_process_reclaim_timeout > $PROCESS_RECLAIM_TIMEOUT_HELPER;
						log -p i -t "$FILE_NAME" "*** RUNNING PROCESS RECLAIM ***";
					fi;
			else
				log -p i -t "$FILE_NAME" "*** PROCESS RECLAIM ALREADY RUNNING WITH DEFAULT TIME PERIOD ***";
			fi;
		fi;

	else
		pkill -f "mem_process_reclaim";	
		log -p i -t "$FILE_NAME" "*** PROCESS RECLAIM IS OFF ***";
	fi;
}

FS_TRIM()
{	
	if [ "$cortexbrain_trim" == "on" ]; then
		if [ "$(pgrep -f fstrim | wc -l)" -eq "0" ]; then
			if [ "$cortexbrain_fstrim_timeout" != "22" ]; then
				echo $cortexbrain_fstrim_timeout > $FSTRIM_TIMEOUT_HELPER;
				$BB nohup $BB sh /res/services/fstrim $cortexbrain_fstrim_timeout > /data/.gabriel/logs/fstrim &
				pgrep -f "/res/services/fstrim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING FSTRIM ***";
			else
				$BB nohup $BB sh /res/services/fstrim > /data/.gabriel/logs/fstrim &
				pgrep -f "/res/services/fstrim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING FSTRIM ***";
			fi;
		else
			if [ "$cortexbrain_fstrim_timeout" != "22" ]; then
				echo $cortexbrain_fstrim_timeout > $FSTRIM_HELPER_TMP;
					if [ `cat $FSTRIM_TIMEOUT_HELPER` != `cat $FSTRIM_HELPER_TMP` ]; then
						pkill -f "fstrim";
						$BB nohup $BB sh /res/services/fstrim $cortexbrain_fstrim_timeout > /data/.gabriel/logs/fstrim &
						pgrep -f "/res/services/fstrim" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
						echo $cortexbrain_fstrim_timeout > $FSTRIM_TIMEOUT_HELPER;
						log -p i -t "$FILE_NAME" "*** RUNNING FSTRIM ***";
					fi;
			else
				log -p i -t "$FILE_NAME" "*** FSTRIM ALREADY RUNNING WITH DEFAULT TIME PERIOD ***";
			fi;
		fi;

	else
		pkill -f "fstrim";	
		log -p i -t "$FILE_NAME" "*** FSTRIM IS OFF ***";
	fi;
}

APP_CACHE()
{	
	if [ "$cortexbrain_app_cache" == "on" ]; then
		if [ "$(pgrep -f clear_file_cache | wc -l)" -eq "0" ]; then
			if [ "$cortexbrain_appcache_timeout" != "22" ]; then
				echo $cortexbrain_appcache_timeout > $APPCACHE_TIMEOUT_HELPER;
				$BB nohup $BB sh /res/services/clear_file_cache $cortexbrain_appcache_timeout > /data/.gabriel/logs/app_cache &
				pgrep -f "/res/services/clear_file_cache" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING CLEAN APP CACHE ***";
			else
				$BB nohup $BB sh /res/services/clear_file_cache > /data/.gabriel/logs/app_cache &
				pgrep -f "/res/services/clear_file_cache" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING CLEAN APP CACHE ***";
			fi;
		else
			if [ "$cortexbrain_appcache_timeout" != "22" ]; then
				echo $cortexbrain_appcache_timeout > $APPCACHE_HELPER_TMP;
					if [ `cat $APPCACHE_TIMEOUT_HELPER` != `cat $APPCACHE_HELPER_TMP` ]; then
						pkill -f "clear_file_cache";
						$BB nohup $BB sh /res/services/clear_file_cache $cortexbrain_appcache_timeout > /data/.gabriel/logs/app_cache &
						pgrep -f "/res/services/clear_file_cache" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
						echo $cortexbrain_appcache_timeout > $APPCACHE_TIMEOUT_HELPER;
						log -p i -t "$FILE_NAME" "*** RUNNING CLEAN APP CACHE ***";
					fi;
			else
				log -p i -t "$FILE_NAME" "*** CLEAN APP CACHE ALREADY RUNNING WITH DEFAULT TIME PERIOD ***";
			fi;
		fi;

	else
		pkill -f "clear_file_cache";	
		log -p i -t "$FILE_NAME" "*** CLEAN APP CACHE IS OFF ***";
	fi;
}

DB_OPT()
{	
	if [ "$cortexbrain_db_opt" == "on" ]; then
		if [ "$(pgrep -f database_optimizing | wc -l)" -eq "0" ]; then
			if [ "$cortexbrain_db_opt_timeout" != "22" ]; then
				echo $cortexbrain_db_opt_timeout > $DP_OPT_TIMEOUT_HELPER;
				$BB nohup $BB sh /res/services/database_optimizing $cortexbrain_db_opt_timeout > /data/.gabriel/logs/db_optimizing &
				pgrep -f "/res/services/database_optimizing" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING DB OPTIMIZATION ***";
			else
				$BB nohup $BB sh /res/services/database_optimizing > /data/.gabriel/logs/db_optimizing &
				pgrep -f "/res/services/database_optimizing" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
				log -p i -t "$FILE_NAME" "*** RUNNING DB OPTIMIZATION ***";
			fi;
		else
			if [ "$cortexbrain_db_opt_timeout" != "22" ]; then
				echo $cortexbrain_db_opt_timeout > $DP_OPT_HELPER_TMP;
					if [ `cat $DP_OPT_TIMEOUT_HELPER` != `cat $DP_OPT_HELPER_TMP` ]; then
						pkill -f "database_optimizing";
						$BB nohup $BB sh /res/services/database_optimizing $cortexbrain_db_opt_timeout > /data/.gabriel/logs/db_optimizing &
						pgrep -f "/res/services/database_optimizing" | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
						echo $cortexbrain_db_opt_timeout > $DP_OPT_TIMEOUT_HELPER;
						log -p i -t "$FILE_NAME" "*** RUNNING DB OPTIMIZATION ***";
					fi;
			else
				log -p i -t "$FILE_NAME" "*** DB OPTIMIZATION ALREADY RUNNING WITH DEFAULT TIME PERIOD ***";
			fi;
		fi;

	else
		pkill -f "database_optimizing";	
		log -p i -t "$FILE_NAME" "*** DB OPTIMIZATION IS OFF ***";
	fi;
}

IO_SCHEDULER()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local state="$1";
		local sys_mmc0_scheduler_tmp="/sys/block/mmcblk0/queue/scheduler";
		local new_scheduler="";
		local tmp_scheduler=$(cat "$sys_mmc0_scheduler_tmp" | sed -n 's/^.*\[\([a-z|A-Z]*\)\].*/\1/p');

		if [ ! -e "$sys_mmc1_scheduler_tmp" ]; then
			sys_mmc1_scheduler_tmp="/dev/null";
		fi;

		if [ "$state" == "awake" ]; then
			new_scheduler="$scheduler";
			if [ "$tmp_scheduler" != "$scheduler" ]; then
				echo "$scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		elif [ "$state" == "sleep" ]; then
			new_scheduler="$sleep_scheduler";
			if [ "$tmp_scheduler" != "$sleep_scheduler" ]; then
				echo "$sleep_scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		fi;

		log -p i -t "$FILE_NAME" "*** IO_SCHEDULER: $state - $new_scheduler ***: done";
	else
		log -p i -t "$FILE_NAME" "*** Cortex IO_SCHEDULER: Disabled ***";
	fi;
}

CPU_CENTRAL_CONTROL()
{
	local state="$1";

	if [ "$cortexbrain_cpu" == "on" ]; then

		if [ "$state" == "awake" ]; then
			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ne "$cpu0_min_freq" ]; then
				echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1)" -ne "$cpu1_min_freq" ]; then
				echo "$cpu1_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2)" -ne "$cpu2_min_freq" ]; then
				echo "$cpu2_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3)" -ne "$cpu3_min_freq" ]; then
				echo "$cpu3_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3;
			fi;

			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)" -ne "$cpu0_max_freq" ]; then
				echo "$cpu0_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu1)" -ne "$cpu1_max_freq" ]; then
				echo "$cpu1_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu1;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu2)" -ne "$cpu2_max_freq" ]; then
				echo "$cpu2_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu2;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu3)" -ne "$cpu3_max_freq" ]; then
				echo "$cpu3_max_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu3;
			fi;

			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "729600" ]; then
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu0;
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu1;
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu2;
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu3;
				echo "300000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;

			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;
		elif [ "$state" == "sleep" ]; then
			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "$cpu0_min_freq" ]; then
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu0;
				echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
				echo "$cpu0_min_freq" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu0;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1)" -ge "$cpu1_min_freq" ]; then
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu1;
				echo "$cpu1_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1;
				echo "$cpu1_min_freq" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu1;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2)" -ge "$cpu2_min_freq" ]; then
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu2;
				echo "$cpu2_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2;
				echo "$cpu2_min_freq" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu2;
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3)" -ge "$cpu3_min_freq" ]; then
				echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu3;
				echo "$cpu3_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3;
				echo "$cpu3_min_freq" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu3;
			fi;
			if [ "$suspend_max_freq" != "max_freq" ]; then
				if [ "$(cat /sys/kernel/msm_cpufreq_limit/suspend_max_freq)" -ne "$suspend_max_freq" ]; then
					echo "$suspend_max_freq" > /sys/kernel/msm_cpufreq_limit/suspend_max_freq;
				fi;
			fi;
			if [ "$suspend_min_freq" != "300000" ]; then
				if [ "$(cat /sys/kernel/msm_cpufreq_limit/suspend_min_freq)" -ne "$suspend_min_freq" ]; then
					echo "$suspend_min_freq" > /sys/kernel/msm_cpufreq_limit/suspend_min_freq;
				fi;
			fi;
		fi;
		log -p i -t "$FILE_NAME" "*** CPU_CENTRAL_CONTROL max_freq:${cpu_max_freq} min_freq:${cpu_min_freq}***: done";
	else
		if [ "$state" == "awake" ]; then
			echo "$cpu0_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu1_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1;
			echo "$cpu2_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2;
			echo "$cpu3_min_freq" > /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3;
			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;
		elif [ "$state" == "sleep" ]; then
			echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu0;
			echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu1;
			echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu2;
			echo "0" > /sys/kernel/msm_cpufreq_limit/cpufreq_min_limit_cpu3;
			if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "729600" ]; then
				echo "300000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;
		fi;
	fi;
}

HOTPLUG_CONTROL()
{
	if [ "$(pgrep -f "/system/bin/thermal-engine" | wc -l)" -eq "1" ]; then
		$BB renice -n -20 -p "$(pgrep -f "/system/bin/thermal-engine")";
	fi;

	if [ "$hotplug" == "msm_hotplug" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
			echo "0" > /sys/kernel/thunderplug/hotplug_enabled;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "0" ]; then
			(
				sleep 1;
				echo "1" > /sys/module/msm_hotplug/msm_enabled;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	elif [ "$hotplug" == "intelli" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
			echo "0" > /sys/kernel/thunderplug/hotplug_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "0" ]; then
			(
				sleep 1;
				echo "1" > /sys/kernel/intelli_plug/intelli_plug_active;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	elif [ "$hotplug" == "alucard" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
			echo "0" > /sys/kernel/thunderplug/hotplug_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "0" ]; then
			(
				sleep 1;
				echo "1" > /sys/kernel/alucard_hotplug/hotplug_enable;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	elif [ "$hotplug" == "thunderplug" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/autosmp/parameters/autosmp_enabled)" == "Y" ]; then
			echo "0" > /sys/module/autosmp/parameters/autosmp_enabled;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "0" ]; then
			(
				sleep 1;
				echo "1" > /sys/kernel/thunderplug/hotplug_enabled;
			)&
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
	fi;
}

WORKQUEUE_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		if [ "$power_efficient" == "on" ]; then
			echo "1" > /sys/module/workqueue/parameters/power_efficient;
		else
			echo "0" > /sys/module/workqueue/parameters/power_efficient;
		fi;
	elif [ "$state" == "sleep" ]; then
		echo "1" > /sys/module/workqueue/parameters/power_efficient;
	fi;
	log -p i -t "$FILE_NAME" "*** WORKQUEUE_CONTROL ***: done";
}

UKSM_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$uksm_gov_on" > /sys/kernel/mm/uksm/cpu_governor;
		echo "$max_cpu_percentage" > /sys/kernel/mm/uksm/max_cpu_percentage;
	elif [ "$state" == "sleep" ]; then
		echo "$uksm_gov_sleep" > /sys/kernel/mm/uksm/cpu_governor;
		echo "$max_cpu_percentage_sleep" > /sys/kernel/mm/uksm/max_cpu_percentage;
	fi;
	log -p i -t "$FILE_NAME" "*** UKSM_CONTROL $state ***: done";
}

SLEEP_GOV_CONTROL()
{
	local state="$1";
	local GOV0_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

	if [ "$state" == "awake" ]; then
		if [ -e /sys/devices/system/cpu/cpufreq/$GOV0_NAMEv/sampling_rate ]; then
			echo "$sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/sampling_rate;	
		fi;
		if [ -e /sys/devices/system/cpu/cpufreq/$GOV0_NAME/timer_rate ]; then
			echo "$sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/timer_rate;
		fi;

	elif [ "$state" == "sleep" ]; then

		if [ -e /sys/devices/system/cpu/cpufreq/$GOV0_NAME/sampling_rate ]; then
			echo "$sleep_sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/sampling_rate;	
		fi;
		if [ -e /sys/devices/system/cpu/cpufreq/$GOV0_NAMEv/timer_rate ]; then
			echo "$sleep_sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/timer_rate;
		fi;
	fi;

	log -p i -t "$FILE_NAME" "*** SLEEP_GOV_CONTROL $state ***: done";
}

SLEEP_HOTPLUG_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then

		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "$hotplug_sample_rate" > /sys/module/msm_hotplug/update_rates;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "$hotplug_sample_rate" > /sys/kernel/intelli_plug/def_sampling_ms;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "$hotplug_sample_rate" > /sys/kernel/alucard_hotplug/hotplug_sampling_rate;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
			echo "$hotplug_sample_rate" > /sys/kernel/thunderplug/sampling_rate;
		fi;

	elif [ "$state" == "sleep" ]; then

		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "$hotplug_sleep_sample_rate" > /sys/module/msm_hotplug/update_rates;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "$hotplug_sleep_sample_rate" > /sys/kernel/intelli_plug/def_sampling_ms;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "$hotplug_sleep_sample_rate" > /sys/kernel/alucard_hotplug/hotplug_sampling_rate;
		fi;
		if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
			echo "$hotplug_sleep_sample_rate" > /sys/kernel/thunderplug/sampling_rate;
		fi;
	fi;

	log -p i -t "$FILE_NAME" "*** SLEEP_HOTPLUG_CONTROL $state ***: done";
}

DROP_CACHE_AUTO()
{
	local state="$1";
	local MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
	local MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
	local MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

	if [ "$state" == "awake" ]; then
		if [ "$cortexbrain_drop_cache_auto_on" == "on" ]; then
			if [ "$MEM_USED_CALC" -gt "$cortexbrain_drop_cache_auto_on_threshold" ]; then
				sync;
				sleep 1;
				sysctl -w vm.drop_caches=2;
				date +%H:%M-%D > /data/.gabriel/logs/drop-cache_auto;
				echo "Cleaned RAM Cache." >> /data/.gabriel/logs/drop-cache_auto;
			fi;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_drop_cache_auto_off" == "on" ]; then
			if [ "$MEM_USED_CALC" -gt "$cortexbrain_drop_cache_auto_off_threshold" ]; then
				sync;
				sleep 1;
				sysctl -w vm.drop_caches=2;
				date +%H:%M-%D > /data/.gabriel/logs/drop-cache_auto;
				echo "Cleaned RAM Cache." >> /data/.gabriel/logs/drop-cache_auto;
			fi;
		fi;
	fi;

}

PROCESS_RECLAIM_AUTO()
{
	local state="$1";
	local RAM_FREE=`vmstat | awk 'NR==3' | awk '{ print $4 }' | cut -c 1-3`;

	if [ "$state" == "awake" ]; then
		if [ "$cortexbrain_process_reclaim_auto_on" == "on" ]; then
			if [ "$RAM_FREE" -lt "$cortexbrain_process_reclaim_auto_on_threshold" ]; then
				for i in $(ls /proc/ | grep -E '^[0-9]+'); do
					if [ "$i" -ge "1500" ] && [ -f /proc/$i/reclaim ]; then
						su -c echo "all" > /proc/$i/reclaim;
					fi;
				done;
				date +%H:%M-%D > /data/.gabriel/logs/process_reclaim_auto;
				echo "Ram Reclaimed." >> /data/.gabriel/logs/process_reclaim_auto;
			fi;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_process_reclaim_auto_off" == "on" ]; then
			if [ "$RAM_FREE" -lt "$cortexbrain_process_reclaim_auto_off_threshold" ]; then
				for i in $(ls /proc/ | grep -E '^[0-9]+'); do
					if [ "$i" -ge "1500" ] && [ -f /proc/$i/reclaim ]; then
						su -c echo "all" > /proc/$i/reclaim;
					fi;
				done;
				date +%H:%M-%D > /data/.gabriel/logs/process_reclaim_auto;
				echo "Ram Reclaimed." >> /data/.gabriel/logs/process_reclaim_auto;
			fi;
		fi;
	fi;

}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	CPU_CENTRAL_CONTROL "awake";
	HOTPLUG_CONTROL;

	if [ "$(cat /data/gabriel_cortex_sleep)" -eq "1" ]; then
		IO_SCHEDULER "awake";
		SLEEP_GOV_CONTROL "awake";
		SLEEP_HOTPLUG_CONTROL "awake";
		WORKQUEUE_CONTROL "awake";
		UKSM_CONTROL "awake";
		MOBILE_DATA "awake";
		WIFI "awake";
		VFS_CACHE_PRESSURE "awake";
		SWAPPINESS "awake";
		NET "awake";
		PROCESS_RECLAIM_AUTO "awake";
		DROP_CACHE_AUTO "awake";
		CLEAN_CACHE;
		PROCESS_RECLAIM;
		FS_TRIM;
		echo "0" > /data/gabriel_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAKEUP ***: done";

	else
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAS NOT SLEEPING ***: done";
	fi;

	if [ "$auto_oom" == "on" ]; then
		sleep 1;
		$BB sh /res/uci.sh oom_config_screen_on $oom_config_screen_on;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	# we only read tele-data when the screen turns off ...
	if [ "$DUMPSYS_STATE" -eq "1" ]; then
		TELE_DATA=`dumpsys telephony.registry`;
	fi;

	CHARGER_STATE=$(cat /sys/class/power_supply/battery/charging_enabled);

	CLEAN_CACHE;
	PROCESS_RECLAIM;
	FS_TRIM;
	APP_CACHE;
	DB_OPT;
	BATTERY_TWEAKS;

	if [ "$CHARGER_STATE" -eq "0" ]; then
		IO_SCHEDULER "sleep";
		SLEEP_GOV_CONTROL "sleep";
		SLEEP_HOTPLUG_CONTROL "sleep";
		CPU_CENTRAL_CONTROL "sleep";
		WORKQUEUE_CONTROL "sleep";
		UKSM_CONTROL "sleep";
		WIFI "sleep";
		MOBILE_DATA "sleep";
		VFS_CACHE_PRESSURE "sleep";
		SWAPPINESS "sleep";
		NET "sleep";
		PROCESS_RECLAIM_AUTO "sleep";
		DROP_CACHE_AUTO "sleep";
		echo "1" > /data/gabriel_cortex_sleep;

		log -p i -t "$FILE_NAME" "*** SLEEP mode ***";
	else
		echo "0" > /data/gabriel_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** NO SLEEP CHARGING ***";
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ]; then
	(while true; do
		while [ "$(cat /sys/module/lm3697/parameters/sleep_state)" == "1" ]; do
			sleep "3";
		done;
		sleep 10; # to be sure in idle
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/module/lm3697/parameters/sleep_state)" == "0" ]; do
			sleep "3";
		done;
		sleep 10; # to be sure in idle
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;
