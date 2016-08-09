#!/sbin/busybox sh

(
	PROFILE=$(cat /data/.gabriel/.active.profile);
	. /data/.gabriel/${PROFILE}.profile;

	if [ "$reset_battery" == "on" ]; then
		echo "reset" > /sys/bus/i2c/devices/1-0036/fuelrst;
		date +%H:%M-%D > /data/crontab/cron-reset-battery;
		echo "Battery Reset" >> /data/crontab/cron-reset-battery;
	fi;
)&
