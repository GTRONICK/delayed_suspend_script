#! /bin/bash
action=$1
time=$2
sTime=$((time*60))
secondsDisplay='00'
actionDisplay='Sleeping'
iconPath=$(realpath icon.png)
filename=$(basename $0)
cooldownNotificationId='noId'
abortNotificationId='noId2'

if [ "$action" = "s" ]; then
    actionDisplay='Sleeping'
else
    actionDisplay='Powering off'
fi

cooldownNotificationId=$(notify-send -i $iconPath -t 0 -a 'System cooldown' "$actionDisplay in $time:00" -i temperature-cold -p)

echo "Started system cooldown, $actionDisplay in $time Minutes..."
echo 'Close this window to abort'

$(
    # We close the abort notification 1 second before the system goes to sleep, so it won't be visible on wake up.
    notifyResult=$(notify-send -t $(((sTime-1)*1000)) -a 'System cooldown' "Click Abort to stop the suspend process" -A ABORT);
    if(($notifyResult==0)) then
        kill -9 $(pgrep $filename)
    fi
) &

for ((i=sTime; i > 0; i--))
do
    sleep 1
    if((i%60<10))
    then
        secondsDisplay="0$((i%60))"
    else
        secondsDisplay=$((i%60))
    fi

    notify-send -t 0 -a 'System cooldown' "$actionDisplay in $((i/60)):$secondsDisplay" -i temperature-cold -r "$cooldownNotificationId"
done

if [ "$action" = "s" ]; then
    # Last notification to avoid persistent popup after waking up.
    notify-send -t 1000 -a 'Delayed Poweroff' "Going to sleep..." -i temperature-cold -r "$cooldownNotificationId"
    systemctl suspend
else
    poweroff
fi
