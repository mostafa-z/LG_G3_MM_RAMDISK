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

# ==============================================================
# OOM-TUNING
# protect services from oom and doing at every state check
# use -1000 & oom_score_adj for kernel 3.x
# ==============================================================

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
	if [ "$cortexbrain_hotplug" == "on" ]; then
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
			if [ "$(cat /sys/kernel/msm_mpdecision/conf/enabled)" == "1" ]; then
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/bricked_hotplug_enable;
				echo "0" > /sys/kernel/msm_mpdecision/conf/enabled;
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
			if [ "$(cat /sys/kernel/msm_mpdecision/conf/enabled)" == "1" ]; then
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/bricked_hotplug_enable;
				echo "0" > /sys/kernel/msm_mpdecision/conf/enabled;
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
			if [ "$(cat /sys/kernel/msm_mpdecision/conf/enabled)" == "1" ]; then
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/bricked_hotplug_enable;
				echo "0" > /sys/kernel/msm_mpdecision/conf/enabled;
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
			if [ "$(cat /sys/kernel/msm_mpdecision/conf/enabled)" == "1" ]; then
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/bricked_hotplug_enable;
				echo "0" > /sys/kernel/msm_mpdecision/conf/enabled;
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
		elif [ "$hotplug" == "bricked" ]; then
			if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
				echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
			fi;
			if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
				echo "0" > /sys/module/msm_hotplug/msm_enabled;
			fi;
			if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
				echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
			fi;
			if [ "$(cat /sys/kernel/thunderplug/hotplug_enabled)" == "1" ]; then
				echo "0" > /sys/kernel/thunderplug/hotplug_enabled;
			fi;
			if [ "$(cat /sys/kernel/msm_mpdecision/conf/enabled)" == "0" ]; then
				(
					sleep 1;
					echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/bricked_hotplug_enable;
					sleep 2;
					echo "1" > /sys/kernel/msm_mpdecision/conf/enabled;
				)&
			fi;
			if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
			fi;
		fi;
	else
		log -p i -t "$FILE_NAME" "*** HOTPLUG_CONTROL IS OFF***";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	GOV0_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
	sys_msm_hp_fll="/sys/module/msm_hotplug/fast_lane_load"
	sys_mmc0_scheduler="/sys/block/mmcblk0/queue/scheduler"
	sys_d_ratio="/proc/sys/vm/dirty_ratio"
	sys_d_back_ratio="/proc/sys/vm/dirty_background_ratio"
	sys_d_exp_cen="/proc/sys/vm/dirty_expire_centisecs"
	sys_d_wrb_cen="/proc/sys/vm/dirty_writeback_centisecs"
	sys_min_f_kb="/proc/sys/vm/min_free_kbytes"
	sys_vfs_cache="/proc/sys/vm/vfs_cache_pressure"
	sys_swappiness="/proc/sys/vm/swappiness"

if [ "$(cat /data/gabriel_cortex_sleep)" -eq "1" ]; then
	echo "$fast_lane_load" > $sys_msm_hp_fll

	echo "$sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/sampling_rate
	echo "$sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/timer_rate

	echo "$hotplug_sample_rate" > /sys/module/msm_hotplug/update_rates
	echo "$hotplug_sample_rate" > /sys/kernel/intelli_plug/def_sampling_ms
	echo "$hotplug_sample_rate" > /sys/kernel/alucard_hotplug/hotplug_sampling_rate
	echo "$hotplug_sample_rate" > /sys/kernel/thunderplug/sampling_rate
	bricked_hotplug_sample_rate=$(($hotplug_sample_rate*1000))
	echo "$bricked_hotplug_sample_rate" > /sys/kernel/msm_mpdecision/conf/startdelay

	echo "$scheduler" > "$sys_mmc0_scheduler"

	echo "$dirty_ratio" > $sys_d_ratio
	echo "$dirty_background_ratio" > $sys_d_back_ratio
	echo "$dirty_expire_centisecs" > $sys_d_exp_cen
	echo "$dirty_writeback_centisecs" > $sys_d_wrb_cen
	echo "$min_free_kbytes" > $sys_min_f_kb
	echo "$vfs_cache_pressure" > $sys_vfs_cache
	echo "$swappiness" > $sys_swappiness

	if [ "$run" == "on" ]; then
		echo "1" > /sys/kernel/mm/uksm/run # to be enable if sleep state was off.
		echo "$uksm_gov_on" > /sys/kernel/mm/uksm/cpu_governor
		echo "$max_cpu_percentage" > /sys/kernel/mm/uksm/max_cpu_percentage
	fi

	if [ "$power_efficient" == "on" ]; then
		echo "1" > /sys/module/workqueue/parameters/power_efficient
	else
		echo "0" > /sys/module/workqueue/parameters/power_efficient
	fi

	CPU_CENTRAL_CONTROL "awake";
	HOTPLUG_CONTROL;
	echo "0" > /data/gabriel_cortex_sleep
fi

if [ "$auto_oom" == "on" ]; then
	sleep 1
	$BB sh /res/uci.sh oom_config_screen_on $oom_config_screen_on
fi
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	CHARGER_STATE=$(cat /sys/class/power_supply/battery/charging_enabled)
	GOV0_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
	sys_msm_hp_fll="/sys/module/msm_hotplug/fast_lane_load"
	sys_mmc0_scheduler="/sys/block/mmcblk0/queue/scheduler"
	sys_d_ratio="/proc/sys/vm/dirty_ratio"
	sys_d_back_ratio="/proc/sys/vm/dirty_background_ratio"
	sys_d_exp_cen="/proc/sys/vm/dirty_expire_centisecs"
	sys_d_wrb_cen="/proc/sys/vm/dirty_writeback_centisecs"
	sys_min_f_kb="/proc/sys/vm/min_free_kbytes"
	sys_vfs_cache="/proc/sys/vm/vfs_cache_pressure"
	sys_swappiness="/proc/sys/vm/swappiness"

if [ "$CHARGER_STATE" -eq "0" ]; then
	echo "$fast_lane_load_sleep" > $sys_msm_hp_fll

	echo "$sleep_sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/sampling_rate
	echo "$sleep_sample_rate" > /sys/devices/system/cpu/cpufreq/$GOV0_NAME/timer_rate

	echo "$hotplug_sleep_sample_rate" > /sys/module/msm_hotplug/update_rates
	echo "$hotplug_sleep_sample_rate" > /sys/kernel/intelli_plug/def_sampling_ms
	echo "$hotplug_sleep_sample_rate" > /sys/kernel/alucard_hotplug/hotplug_sampling_rate
	echo "$hotplug_sleep_sample_rate" > /sys/kernel/thunderplug/sampling_rate
	bricked_hotplug_sample_rate=$(($hotplug_sleep_sample_rate*1000))
	echo "$bricked_hotplug_sample_rate" > /sys/kernel/msm_mpdecision/conf/startdelay

	echo "$sleep_scheduler" > "$sys_mmc0_scheduler"

	echo "$dirty_ratio_sleep" > $sys_d_ratio
	echo "$dirty_background_ratio_sleep" > $sys_d_back_ratio
	echo "$dirty_expire_centisecs_sleep" > $sys_d_exp_cen
	echo "$dirty_writeback_centisecs_sleep" > $sys_d_wrb_cen
	echo "$min_free_kbytes_sleep" > $sys_min_f_kb
	echo "$vfs_cache_pressure_sleep" > $sys_vfs_cache
	echo "$swappiness_sleep" > $sys_swappiness

	if [ "$run" == "on" ] && [ "$uksm_sleep" == "on" ]; then
		echo "$uksm_gov_sleep" > /sys/kernel/mm/uksm/cpu_governor
		echo "$max_cpu_percentage_sleep" > /sys/kernel/mm/uksm/max_cpu_percentage
	elif [ "$run" == "on" ] && [ "$uksm_sleep" == "off" ]; then
		echo "0" > /sys/kernel/mm/uksm/run
	fi

	echo "1" > /sys/module/workqueue/parameters/power_efficient

	CPU_CENTRAL_CONTROL "sleep";
	echo "1" > /data/gabriel_cortex_sleep
fi
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ]; then
	while :
		do
		while [ "$(cat /sys/module/lm3697/parameters/sleep_state)" -ne "0" ]; do
			sleep "3"
		done
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/module/lm3697/parameters/sleep_state)" -ne "1" ]; do
			sleep "3"
		done
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done
fi;
