#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.

BB=/sbin/busybox

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

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

# clean old modules from /system and add new from ramdisk
if [ ! -d /system/lib/modules ]; then
        $BB mkdir /system/lib/modules;
fi;
cd /lib/modules/;
for i in *.ko; do
        $BB rm -f /system/lib/modules/"$i";
done;
cd /;

$BB chmod 755 /lib/modules/*.ko;
$BB cp -a /lib/modules/*.ko /system/lib/modules/;

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod -R 755 /system/etc/init.d/;
fi;

OPEN_RW;

# start CROND by tree root, so it's will not be terminated.
	nohup sh /res/crontab_service/service.sh;

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

INTERACTIVE_TUNING()
{

	echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
    echo "20000 1400000:40000 1700000:20000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay;
    echo "90" > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load;
    echo "1497600" > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq;
    echo "1" > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy;
    echo "100000" > /sys/devices/system/cpu/cpufreq/interactive/max_freq_hysteresis;
    echo "40000" > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time;
    echo "85 1500000:90 1800000:70" > /sys/devices/system/cpu/cpufreq/interactive/target_loads;
    echo "30000" > /sys/devices/system/cpu/cpufreq/interactive/timer_rate;
    echo "30000" > /sys/devices/system/cpu/cpufreq/interactive/timer_slack;
}
SYSTEM_TUNING()
{
    echo "500" > /sys/module/msm_hotplug/down_lock_duration;
    echo "2500" > /sys/module/msm_hotplug/boost_lock_duration;
    echo "200 5:100 50:50 350:200" > /sys/module/msm_hotplug/update_rates;
    echo "100" > /sys/module/msm_hotplug/fast_lane_load;

    echo "500" > /sys/module/cpu_boost/parameters/input_boost_ms;
    echo "20" > /sys/module/cpu_boost/parameters/boost_ms;
    echo "0:1497600 1:1497600 2:1497600 3:1497600" > /sys/module/cpu_boost/parameters/input_boost_freq;
    echo "30" > /sys/module/cpu_boost/parameters/migration_load_threshold;
    echo "960000" > /sys/module/cpu_boost/parameters/sync_threshold;

    echo "1" > /sys/module/state_notifier/parameters/enabled;

# Adaptive LMK
# ((65 * 1024)=66560) * 4 = 266 MB
    echo "1" > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
    echo "66560" > /sys/module/lowmemorykiller/parameters/vmpressure_file_min;
#   echo "74240" > /sys/module/lowmemorykiller/parameters/vmpressure_file_min;

# Tune LMK with values we love
	echo "1536,2048,4096,16384,28672,32768" > /sys/module/lowmemorykiller/parameters/minfree
	echo "32" > /sys/module/lowmemorykiller/parameters/cost

# Per-process reclaim
    echo "1" > /sys/module/process_reclaim/parameters/enable_process_reclaim;
	echo "1" > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
	echo "100" > /sys/module/process_reclaim/parameters/pressure_max
    echo "10" > /sys/module/process_reclaim/parameters/pressure_min;
    echo "1024" > /sys/module/process_reclaim/parameters/per_swap_size;
    echo "70" > /sys/module/process_reclaim/parameters/pressure_max;
    echo "30" > /sys/module/process_reclaim/parameters/swap_opt_eff;

# VM tuning
    echo "20" > /proc/sys/vm/dirty_background_ratio;
    echo "200" > /proc/sys/vm/dirty_expire_centisecs;
    echo "40" > /proc/sys/vm/dirty_ratio;
    echo "0" > /proc/sys/vm/page-cluster;
    echo "0" > /proc/sys/vm/swappiness;
    echo "80" > /proc/sys/vm/vfs_cache_pressure;

# Calibrate display
	echo "250 250 255" > /sys/devices/platform/kcal_ctrl.0/kcal
	echo 243 > /sys/devices/platform/kcal_ctrl.0/kcal_sat
	echo 1515 > /sys/devices/platform/kcal_ctrl.0/kcal_hue
	echo 250 > /sys/devices/platform/kcal_ctrl.0/kcal_val

# Set read ahead
	echo 1024 | tee /sys/block/mmcblk0/queue/read_ahead_kb
	echo 1024 | tee /sys/block/mmcblk1/queue/read_ahead_kb
# Set i/o scheduler
	echo cfq | tee /sys/block/mmcblk0/queue/scheduler
	echo cfq | tee /sys/block/mmcblk1/queue/scheduler
# stop mpdecision
	stop mpdecision

	echo "[defcon] System_Tuning : Completed" >> /data/boot_log
}

# oom and mem perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree

# make sure we own the device nodes
$BB chown system /sys/devices/system/cpu/cpufreq/interactive/*
$BB chown system /sys/devices/system/cpu/cpu0/cpufreq/*
$BB chown system /sys/devices/system/cpu/cpu1/online
$BB chown system /sys/devices/system/cpu/cpu2/online
$BB chown system /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/stats/*
$BB chmod 666 /sys/devices/system/cpu/cpufreq/all_cpus/*
$BB chmod 666 /sys/devices/system/cpu/cpu1/online
$BB chmod 666 /sys/devices/system/cpu/cpu2/online
$BB chmod 666 /sys/devices/system/cpu/cpu3/online

LOG=/data/boot_log
BUSYBOX_VER=$(busybox | grep "BusyBox v" | cut -c0-15);
echo "$BUSYBOX_VER" > $LOG;

# start CORTEX by tree root, so it's will not be terminated.
sed -i "s/cortexbrain_background_process=[0-1]*/cortexbrain_background_process=1/g" /sbin/ext/cortexbrain-tune.sh;
if [ "$(pgrep -f "cortexbrain-tune.sh" | wc -l)" -eq "0" ]; then
	nohup sh /sbin/ext/cortexbrain-tune.sh > /data/cortex.txt &
fi;

# copy cron files
$BB cp -a /res/crontab/ /data/
if [ ! -e /data/crontab/custom_jobs ]; then
	$BB touch /data/crontab/custom_jobs;
	$BB chmod 777 /data/crontab/custom_jobs;
fi;

# disable debugging on some modules
echo "N" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/devices/fe12f000.slim/debug_mask
echo "0" > /sys/module/smd/parameters/debug_mask
echo "0" > /sys/module/smem/parameters/debug_mask
echo "0" > /sys/module/rpm_regulator_smd/parameters/debug_mask
echo "0" > /sys/module/ipc_router/parameters/debug_mask
echo "0" > /sys/module/event_timer/parameters/debug_mask
echo "0" > /sys/module/smp2p/parameters/debug_mask
echo "0" > /sys/module/msm_serial_hs_lge/parameters/debug_mask
#	echo "0" > /sys/module/msm_hotplug/parameters/debug_mask
#	echo "0" > /sys/module/cpufreq_limit/parameters/debug_mask
echo "0" > /sys/module/rpm_smd/parameters/debug_mask
echo "0" > /sys/module/smd_pkt/parameters/debug_mask
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask
echo "0" > /sys/module/qpnp_regulator/parameters/debug_mask
echo "0" > /sys/module/binder/parameters/debug_mask
echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask
echo "0" > /sys/module/alarm_dev/parameters/debug_mask
echo "0" > /sys/module/mpm_of/parameters/debug_mask
echo "0" > /sys/module/msm_pm/parameters/debug_mask
echo "0" > /sys/module/spm_v2/parameters/debug_mask
echo "0" > /sys/module/alu_t_boost/parameters/debug_mask
echo "0" > /sys/module/lpm_levels/parameters/debug_mask
echo "0" > /sys/module/ipc_router_smd_xprt/parameters/debug_mask
echo "0" > /sys/module/x_tables/parameters/debug_mask
echo "0" > /sys/module/lge_touch_core/parameters/debug_mask

OPEN_RW;

# set ondemand  & SYSTEM tuning.
INTERACTIVE_TUNING;
SYSTEM_TUNING;

OPEN_RW;

# Fix critical perms again
CRITICAL_PERM_FIX;

# tune I/O controls to boost I/O performance

#This enables the user to disable the lookup logic involved with IO
#merging requests in the block layer. By default (0) all merges are
#enabled. When set to 1 only simple one-hit merges will be tried. When
#set to 2 no merge algorithms will be tried (including one-hit or more
#complex tree/hash lookups).
if [ "$(cat /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/queue/nomerges)" != "2" ]; then
	echo "2" > /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/queue/nomerges;
	echo "2" > /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/mmcblk0rpmb/queue/nomerges;
fi;

#If this option is '1', the block layer will migrate request completions to the
#cpu "group" that originally submitted the request. For some workloads this
#provides a significant reduction in CPU cycles due to caching effects.
#For storage configurations that need to maximize distribution of completion
#processing setting this option to '2' forces the completion to run on the
#requesting cpu (bypassing the "group" aggregation logic).
if [ "$(cat /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/queue/rq_affinity)" != "1" ]; then
	echo "1" > /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/queue/rq_affinity;
	echo "1" > /sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0/mmcblk0rpmb/queue/rq_affinity;
fi;

(
	sleep 30;

	# stop google service and restart it on boot. this remove high cpu load and ram leak!
	if [ "$($BB pidof com.google.android.gms | wc -l)" -eq "1" ]; then
		$BB kill "$($BB pidof com.google.android.gms)";
	fi;
	if [ "$($BB pidof com.google.android.gms.unstable | wc -l)" -eq "1" ]; then
		$BB kill "$($BB pidof com.google.android.gms.unstable)";
	fi;
	if [ "$($BB pidof com.google.android.gms.persistent | wc -l)" -eq "1" ]; then
		$BB kill "$($BB pidof com.google.android.gms.persistent)";
	fi;
	if [ "$($BB pidof com.google.android.gms.wearable | wc -l)" -eq "1" ]; then
		$BB kill "$($BB pidof com.google.android.gms.wearable)";
	fi;

	# Google Services battery drain fixer by Alcolawl@xda
	# http://forum.xda-developers.com/google-nexus-5/general/script-google-play-services-battery-t3059585/post59563859
	pm enable com.google.android.gms/.update.SystemUpdateActivity
	pm enable com.google.android.gms/.update.SystemUpdateService
	pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver
	pm enable com.google.android.gms/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver
	pm enable com.google.android.gsf/.update.SystemUpdateActivity
	pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity
	pm enable com.google.android.gsf/.update.SystemUpdateService
	pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver

	# script finish here, so let me know when
	TIME_NOW=$(date)
	echo "$TIME_NOW" >> /data/boot_log

	$BB mount -o remount,ro /system;
)&
