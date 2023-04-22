# For auto restart app

logPath=/tmp/killAndStart.log
app=/Applications/SlowQuitApps.app #should make sure the name is unique
grepAppName=SlowQuitApps.app

date=`date +%Y-%m-%d:%H:%M:%S`
hour=`date +%H`
echo '-------------------------------------------------------' >> ${logPath}
echo $date' Starting...' >> ${logPath}

# Kill App
pkill -f ${grepAppName}
echo $date" Kill App ${grepAppName}" >> ${logPath}

if test ! -w ${logPath}
then
    touch ${logPath}
    chmod 777 ${logPath}
fi

open ${app} >> ${logPath} 2>&1
isRetry=0
function start(){
        pid=`pgrep -f ${grepAppName}`
        if test -z $pid
        then
               date=`date +%Y-%m-%d:%H:%M:%S`
               echo $date' No pid found' >> ${logPath}

               if [ $isRetry == 1 ]
               then
                     echo $date' Restart failed, retrying...' >> ${logPath}
               fi
               open ${app} >> ${logPath} 2>&1
               isRetry=1
               start
        else
               date=`date +%Y-%m-%d:%H:%M:%S`
               if [ $isRetry == 1 ]
               then
                   echo $date' Restart success!' >> ${logPath}
               else
                   echo $date' Error..' >> ${logPath}
               fi
               echo $date' Success, pid is '$pid >> ${logPath}
        fi

}
