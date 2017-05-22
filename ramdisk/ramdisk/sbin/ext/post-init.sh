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

if [ ! -e /hotplugs/ ]; then
	$BB mkdir /hotplugs/;
fi;

# some nice thing for dev
if [ ! -e /cpufreq ]; then
	$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq/ /cpufreq;
	$BB ln -s /sys/devices/system/cpu/cpufreq/all_cpus/ /all_cpus;
	$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
	$BB ln -s /sys/module/cpu_boost/parameters/ /cpu_boost;
	$BB ln -s /sys/kernel/msm_cpufreq_limit/ /cpufreq_limit;
	$BB ln -s /sys/module/msm_thermal/parameters/ /cputemp;
	$BB ln -s /sys/kernel/alucard_hotplug/ /hotplugs/alucard;
	$BB ln -s /sys/kernel/intelli_plug/ /hotplugs/intelli;
	$BB ln -s /sys/module/msm_hotplug/ /hotplugs/msm_hotplug;
	$BB ln -s /sys/kernel/thunderplug/ /hotplugs/thunderplug;
	$BB ln -s /sys/kernel/msm_mpdecision/conf/ /hotplugs/msm_mpdecision;
fi;

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

OPEN_RW;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 775 /hotplugs/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod 06755 /sbin/busybox;
	$BB chmod 06755 /system/xbin/busybox;
}
CRITICAL_PERM_FIX;

SYSTEM_TUNING()
{
# Tune entropy parameters.
#echo "512" > /proc/sys/kernel/random/read_wakeup_threshold;
#echo "256" > /proc/sys/kernel/random/write_wakeup_threshold;

echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
sleep 0.5;
stop mpdecision;

#echo ondemandx > /cpufreq/scaling_governor;
#echo ondemandx > /all_cpus/scaling_governor_cpu1;
#echo ondemandx > /all_cpus/scaling_governor_cpu2;
#echo ondemandx > /all_cpus/scaling_governor_cpu3;

#echo "750" > /cpu_boost/input_boost_ms;

#echo "2457600" > /cpufreq_limit/cpufreq_max_limit_cpu0;
#echo "2457600" > /cpufreq_limit/cpufreq_max_limit_cpu1;
#echo "2457600" > /cpufreq_limit/cpufreq_max_limit_cpu2;
#echo "2457600" > /cpufreq_limit/cpufreq_max_limit_cpu3;
#echo "300000" > /cpufreq_limit/cpufreq_min_limit_cpu0;
#echo "300000" > /cpufreq_limit/cpufreq_min_limit_cpu1;
#echo "300000" > /cpufreq_limit/cpufreq_min_limit_cpu2;
#echo "300000" > /cpufreq_limit/cpufreq_min_limit_cpu3;
#echo "1497600" > /cpufreq_limit/suspend_max_freq;
#echo "268800" > /cpufreq_limit/suspend_min_freq;

#echo "578000000" > /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/max_freq
#echo "100000000" > /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/min_freq

echo "0" > /sys/module/msm_thermal/core_control/enabled;
echo "1" > /cputemp/intelli_enabled;

#echo quiet > /sys/kernel/mm/uksm/cpu_governor;
#echo "1000" > /sys/kernel/mm/uksm/sleep_millisecs;

# KERNEL-TWEAKS
echo "0" > /proc/sys/vm/oom_kill_allocating_task;
echo "0" > /proc/sys/vm/panic_on_oom;
echo "30" > /proc/sys/kernel/panic;
echo "0" > /proc/sys/kernel/panic_on_oops;
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
$BB chmod 666 /cpufreq_limit/*
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/stats/*
$BB chmod 666 /sys/devices/system/cpu/cpu1/online
$BB chmod 666 /sys/devices/system/cpu/cpu2/online
$BB chmod 666 /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /hotplugs/*
$BB chmod 666 /sys/module/msm_thermal/parameters/*
$BB chmod 666 /sys/class/kgsl/kgsl-3d0/max_gpuclk
$BB chmod 666 /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/governor
$BB chmod 666 /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/*_freq

if [ ! -d /data/.gabriel ]; then
	$BB mkdir -p /data/.gabriel;
fi;

if [ ! -d /data/.gabriel/logs ]; then
	$BB mkdir -p /data/.gabriel/logs;
fi;

# reset profiles auto trigger to be used by kernel ADMIN, in case of need, if new value added in default profiles
# just set numer $RESET_MAGIC + 1 and profiles will be reset one time on next boot with new kernel.
# incase that ADMIN feel that something wrong with global STweaks config and profiles, then ADMIN can add +1 to CLEAN_gabriel_DIR
# to clean all files on first boot from /data/.gabriel/ folder.
RESET_MAGIC=2;
CLEAN_gabriel_DIR=1;

if [ ! -e /data/.gabriel/reset_profiles ]; then
	echo "$RESET_MAGIC" > /data/.gabriel/reset_profiles;
fi;
if [ ! -e /data/reset_gabriel_dir ]; then
	echo "$CLEAN_gabriel_DIR" > /data/reset_gabriel_dir;
fi;
if [ -e /data/.gabriel/.active.profile ]; then
	PROFILE=$(cat /data/.gabriel/.active.profile);
else
	echo "default" > /data/.gabriel/.active.profile;
	PROFILE=$(cat /data/.gabriel/.active.profile);
fi;
if [ "$(cat /data/reset_gabriel_dir)" -eq "$CLEAN_gabriel_DIR" ]; then
	if [ "$(cat /data/.gabriel/reset_profiles)" != "$RESET_MAGIC" ]; then
		if [ ! -e /data/.gabriel_old ]; then
			mkdir /data/.gabriel_old;
		fi;
		cp -a /data/.gabriel/*.profile /data/.gabriel_old/;
		$BB rm -f /data/.gabriel/*.profile;
		if [ -e /data/data/com.af.synapse/databases ]; then
			$BB rm -R /data/data/com.af.synapse/databases;
		fi;
		echo "$RESET_MAGIC" > /data/.gabriel/reset_profiles;
	else
		echo "no need to reset profiles or delete .gabriel folder";
	fi;
else
	# Clean /data/.gabriel/ folder from all files to fix any mess but do it in smart way.
	if [ -e /data/.gabriel/"$PROFILE".profile ]; then
		cp /data/.gabriel/"$PROFILE".profile /sdcard/"$PROFILE".profile_backup;
	fi;
	if [ ! -e /data/.gabriel_old ]; then
		mkdir /data/.gabriel_old;
	fi;
	cp -a /data/.gabriel/* /data/.gabriel_old/;
	$BB rm -f /data/.gabriel/*
	if [ -e /data/data/com.af.synapse/databases ]; then
		$BB rm -R /data/data/com.af.synapse/databases;
	fi;
	echo "$CLEAN_gabriel_DIR" > /data/reset_gabriel_dir;
	echo "$RESET_MAGIC" > /data/.gabriel/reset_profiles;
	echo "$PROFILE" > /data/.gabriel/.active.profile;
fi;

[ ! -f /data/.gabriel/default.profile ] && cp -a /res/customconfig/default.profile /data/.gabriel/default.profile;
[ ! -f /data/.gabriel/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.gabriel/battery.profile;
[ ! -f /data/.gabriel/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.gabriel/performance.profile;
[ ! -f /data/.gabriel/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.gabriel/extreme_performance.profile;
[ ! -f /data/.gabriel/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.gabriel/extreme_battery.profile;
[ ! -f /data/.gabriel/gabriel.profile ] && cp -a /res/customconfig/gabriel.profile /data/.gabriel/gabriel.profile;
[ ! -f /data/.gabriel/suigintou.profile ] && cp -a /res/customconfig/gabriel.profile /data/.gabriel/suigintou.profile;
[ ! -f /data/.gabriel/dcop7.profile ] && cp -a /res/customconfig/gabriel.profile /data/.gabriel/dcop7.profile;
[ ! -f /data/.gabriel/salvation.profile ] && cp -a /res/customconfig/gabriel.profile /data/.gabriel/salvation.profile;

$BB chmod -R 0777 /data/.gabriel/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

# Load parameters for Synapse
DEBUG=/data/.gabriel/;
BUSYBOX_VER=$(busybox | grep "BusyBox v" | cut -c0-15);
echo "$BUSYBOX_VER" > $DEBUG/busybox_ver;

# start CORTEX by tree root, so it's will not be terminated.
sed -i "s/cortexbrain_background_process=[0-1]*/cortexbrain_background_process=1/g" /sbin/ext/cortexbrain-tune.sh;
if [ "$(pgrep -f "cortexbrain-tune.sh" | wc -l)" -eq "0" ]; then
	nohup sh /sbin/ext/cortexbrain-tune.sh > /data/.gabriel/cortex.txt &
fi;

# kill charger logo binary to prevent ROM running it.
CHECK_BOOT_STATE=$($BB cat /proc/cmdline | $BB grep "androidboot.mode=" | $BB wc -l);
if [ "$CHECK_BOOT_STATE" -eq "0" ]; then
	$BB rm /sbin/chargerlogo;
	$BB rm /charger;
fi;

if [ "$stweaks_boot_control" == "yes" ]; then
	# apply Synapse monitor
	$BB sh /res/synapse/uci reset;
	# apply Gabriel settings
	$BB sh /res/uci_boot.sh apply;
	$BB mv /res/uci_boot.sh /res/uci.sh;
else
	$BB mv /res/uci_boot.sh /res/uci.sh;
fi;

# disable debugging
echo "0" > /sys/module/lge_touch_core/parameters/debug_mask
echo "0" > /sys/module/lm3697/parameters/debug_mask
echo "0" > /sys/module/ipc_router/parameters/debug_mask
echo "0" > /sys/module/smp2p/parameters/debug_mask
echo "0" > /sys/module/msm_serial_hs_lge/parameters/debug_mask
echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask
echo "0" > /sys/module/alarm_dev/parameters/debug_mask
echo "0" > /sys/module/mpm_of/parameters/debug_mask
echo "0" > /sys/module/msm_pm/parameters/debug_mask
echo "0" > /sys/module/powersuspend/parameters/debug_mask
#	echo "0" > /sys/module/msm_hotplug/parameters/debug_mask
#	echo "0" > /sys/module/cpufreq_limit/parameters/debug_mask

OPEN_RW;

# set system tuning.
SYSTEM_TUNING;

# Start any init.d scripts that may be present in the rom or added by the user
$BB chmod -R 755 /system/etc/init.d/;
if [ "$init_d" == "on" ]; then
	(
		$BB nohup $BB run-parts /system/etc/init.d/ > /data/.gabriel/init.d.txt &
	)&
else
	if [ -e /system/etc/init.d/99SuperSUDaemon ]; then
		$BB nohup $BB sh /system/etc/init.d/99SuperSUDaemon > /data/.gabriel/root.txt &
	else
		echo "no root script in init.d";
	fi;
fi;

OPEN_RW;

# Fix critical perms again after init.d mess
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

	# get values from profile
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/"$PROFILE".profile;

if [ "$protect_systemui_oom" == "yes" ] && [ "$stweaks_boot_control" == "yes" ]; then
	# Now wait for the rom to finish booting up
	# (by checking for the android acore process)
	# and exclude it from OOM
	while ! $BB pgrep com.android.systemui ; do
	  $BB sleep 1
	done
	echo "[Gabriel-Kernel] systemui detected" > /dev/kmsg
	$BB pgrep -f pgrep com.android.systemui | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done
	# nova launcher, smooth ui & less resource, i'm using it
	$BB pgrep -f coilsw.launcher | while read PID; do echo -1000 > /proc/$PID/oom_score_adj; done

	echo "[Gabriel-Kernel] Protect systemui enabled" > /dev/kmsg
else
	echo "[Gabriel-Kernel] Protect systemui disabled" > /dev/kmsg 
fi;

if [ "$google_services_fix" == "yes" ] && [ "$stweaks_boot_control" == "yes" ]; then
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

	echo "[Gabriel-Kernel] google services fix enabled" > /dev/kmsg
else
	echo "[Gabriel-Kernel] google services fix disabled" > /dev/kmsg 
fi;

	$BB mount -o remount,ro /system;

	while [ "$(cat /sys/class/thermal/thermal_zone5/temp)" -ge "65" ]; do
		sleep 5;
	done;

	if [ "$(cat /sys/module/state_notifier/parameters/state_suspended)" == "N" ]; then
		$BB sh /res/uci.sh cpu0_min_freq "$cpu0_min_freq";
		$BB sh /res/uci.sh cpu1_min_freq "$cpu1_min_freq";
		$BB sh /res/uci.sh cpu2_min_freq "$cpu2_min_freq";
		$BB sh /res/uci.sh cpu3_min_freq "$cpu3_min_freq";

		$BB sh /res/uci.sh cpu0_max_freq "$cpu0_max_freq";
		$BB sh /res/uci.sh cpu1_max_freq "$cpu1_max_freq";
		$BB sh /res/uci.sh cpu2_max_freq "$cpu2_max_freq";
		$BB sh /res/uci.sh cpu3_max_freq "$cpu3_max_freq";
	fi;

	if [ "$restart_lge_systemui" == "yes" ] && [ "$stweaks_boot_control" == "yes" ]; then
		pkill -f com.lge.launcher2;
		echo "[Gabriel-Kernel] LGe Launcher2 restarted" > /dev/kmsg
	fi;

)&
