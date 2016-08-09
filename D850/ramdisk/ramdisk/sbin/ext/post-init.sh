#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.

BB=/sbin/busybox

# protect init from oom
if [ -f /system/xbin/su ]; then
	su -c echo "-1000" > /proc/1/oom_score_adj;
fi;

OPEN_RW()
{
	if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /;
	fi;
	if [ "$($BB mount | grep system | grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /system;
	fi;
}
OPEN_RW;

# run ROM scripts
$BB sh /system/etc/init.qcom.post_boot.sh;

OPEN_RW;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chown -R root:root /lib;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod 06755 /sbin/busybox;
	$BB chmod 06755 /system/xbin/busybox;
}
CRITICAL_PERM_FIX;

SYSTEM_TUNING()
{
# Tune entropy parameters.
echo "512" > /proc/sys/kernel/random/read_wakeup_threshold;
echo "256" > /proc/sys/kernel/random/write_wakeup_threshold;
# Tune hotplug parameters
stop mpdecision;
sleep 0.5;
ehco "1" > /sys/class/misc/mako_hotplug_control/enabled;
ehco "1497600" > /sys/class/misc/mako_hotplug_control/cpufreq_unplug_limit;
ehco "5" > /sys/class/misc/mako_hotplug_control/load_threshold;
# Tune thermal parameters.
echo "N" > /sys/module/msm_thermal/parameters/intelli_enabled;
# add these parameters for later use
echo "1" > /sys/module/msm_thermal/core_control/enabled;
echo "68" > /sys/module/msm_thermal/parameters/core_limit_temp_degC;
echo "65" > /sys/module/msm_thermal/parameters/limit_temp_degC;
echo "5" > /sys/module/msm_thermal/parameters/temp_hysteresis_degC;
echo "5" > /sys/module/msm_thermal/parameters/core_temp_hysteresis_degC;
echo "9" > /sys/module/msm_thermal/parameters/thermal_limit_low;
echo "N" > /sys/module/msm_thermal/parameters/immediately_limit_stop;
echo "1" > /sys/module/msm_thermal/parameters/temp_safety;
# Tune gpu parameters
#echo "1" > /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate;
#echo "2" > /sys/module/simple_gpu_algorithm/parameters/simple_laziness;
#echo "7000" > /sys/module/simple_gpu_algorithm/parameters/simple_ramp_threshold;

#		local MMC=$(find /sys/block/mmc*);
#		for i in $MMC; do
#			echo "row" > "$i"/queue/scheduler;
#			echo "0" > "$i"/queue/rotational;
#			echo "0" > "$i"/queue/iostats;
#			echo "2" > "$i"/queue/nomerges;
#		done;

		# This controls how many requests may be allocated
		# in the block layer for read or write requests.
		# Note that the total allocated number may be twice
		# this amount, since it applies only to reads or writes
		# (not the accumulated sum).
#		echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

		# our storage is 16/32GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
#		echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb;
#		echo "1024" > /sys/block/mmcblk0/bdi/read_ahead_kb;

#		echo "45" > /proc/sys/fs/lease-break-time;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;
		echo "0" > /proc/sys/kernel/panic_on_oops;
# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
#		echo "20" > /proc/sys/vm/dirty_background_ratio; # default: 20
#		echo "25" > /proc/sys/vm/dirty_ratio; # default: 25
#		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
#		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
#		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
#		echo "3" > /proc/sys/vm/page-cluster; # default: 3
#		echo "8192" > /proc/sys/vm/min_free_kbytes; #default: 2572
		# mem calc here in pages. so 16384 x 4 = 64MB reserved for fast access by kernel and VM
#		echo "32768" > /proc/sys/vm/mmap_min_addr; #default: 32768
#		echo "69632" > /sys/module/lowmemorykiller/parameters/vmpressure_file_min;
#		echo "1" > /sys/module/process_reclaim/parameters/enable_process_reclaim;
#		echo "80" > /sys/module/process_reclaim/parameters/pressure_max;
#		echo "50" > /sys/module/process_reclaim/parameters/pressure_min;
		#echo "80" > /proc/sys/vm/swappiness;
}

# oom and mem perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree

# make sure we own the device nodes
$BB chown system /sys/devices/system/cpu/cpu0/cpufreq/*
$BB chown system /sys/devices/system/cpu/cpu1/online
$BB chown system /sys/devices/system/cpu/cpu2/online
$BB chown system /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/stats/*
$BB chmod 666 /sys/devices/system/cpu/cpu1/online
$BB chmod 666 /sys/devices/system/cpu/cpu2/online
$BB chmod 666 /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/module/msm_thermal/parameters/*
$BB chmod 666 /sys/class/kgsl/kgsl-3d0/max_gpuclk
$BB chmod 666 /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/governor
$BB chmod 666 /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/*_freq

# disable debugging
echo "0" > /sys/module/lge_touch_core/parameters/debug_mask;

OPEN_RW;

# set system tuning.
SYSTEM_TUNING;

	while [ "$(cat /sys/class/thermal/thermal_zone5/temp)" -ge "65" ]; do
		sleep 5;
	done;

	echo "Y" > /sys/module/msm_thermal/parameters/intelli_enabled;
	echo "0" > /sys/module/msm_thermal/core_control/enabled;
	echo "72" > /sys/module/msm_thermal/parameters/core_limit_temp_degC;
	echo "68" > /sys/module/msm_thermal/parameters/limit_temp_degC;
	echo "10" > /sys/module/msm_thermal/parameters/temp_hysteresis_degC;
	echo "10" > /sys/module/msm_thermal/parameters/core_temp_hysteresis_degC;
	echo "7" > /sys/module/msm_thermal/parameters/thermal_limit_low;
	echo "65" > /sys/module/msm_thermal/parameters/freq_limit_debug;
	echo "0" > /sys/class/misc/mako_hotplug_control/enabled;
	echo "1728000" > /sys/class/misc/mako_hotplug_control/cpufreq_unplug_limit;
	echo "80" > /sys/class/misc/mako_hotplug_control/load_threshold;
	sleep 0.5;
	start mpdecision;
	echo "2457600" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

	# Play sound 
	am start -a android.intent.action.VIEW -d file:///res/misc/notification.wav -t audio/wav

	$BB mount -o remount,ro /system;

