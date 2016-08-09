#!/sbin/busybox sh

PROFILE=$(cat /data/.gabriel/.active.profile);
. /data/.gabriel/${PROFILE}.profile;

if [ "$cron_reset_systemui" == "on" ]; then
	pkill -f com.android.systemui
	date +%H:%M-%D > /data/crontab/cron-reset-systemui;
	echo "SystemUI Drain Terminated." >> /data/crontab/cron-reset-systemui;
fi;
