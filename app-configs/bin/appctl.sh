#!/bin/bash

# 修改APP_NAME为云效上的应用名
APP_NAME=application


PROG_NAME=$0
ACTION=$1
APP_START_TIMEOUT=20    # 等待应用启动的时间
APP_PORT=3000          # 应用端口
HEALTH_CHECK_URL=http://127.0.0.1:${APP_PORT}  # 应用健康检查URL
# TODO CHANGE TO
APP_HOME=/tmp/${APP_NAME} # 从package.tgz中解压出来的jar包放到这个目录下
STD_OUT=${APP_HOME}/logs/start.log  #应用的启动日志
NODE_MAIN=app.js

# 创建出相关目录
mkdir -p ${APP_HOME}
mkdir -p ${APP_HOME}/logs
usage() {
    echo "Usage: $PROG_NAME {start|stop|restart}"
    exit 2
}

health_check() {
    exptime=0
    echo "checking ${HEALTH_CHECK_URL}"
    while true
        do
            status_code=`/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w %{http_code}  ${HEALTH_CHECK_URL}`
            if [ "$?" != "0" ]; then
               echo -n -e "\rapplication not started"
            else
                echo "code is $status_code"
                if [ "$status_code" == "200" ];then
                    break
                fi
            fi
            sleep 1
            ((exptime++))

            echo -e "\rWait app to pass health check: $exptime..."

            if [ $exptime -gt ${APP_START_TIMEOUT} ]; then
                echo 'app start failed'
               exit 1
            fi
        done
    echo "check ${HEALTH_CHECK_URL} success"
}
start_application() {
    echo "node environment"
    node --version
    npm --version
    echo "starting nodejs process"
    nohup npm start > ${STD_OUT} 2>&1 &
    echo "started nodejs process"
}

stop_application() {
   checkjavapid=`ps -ef | grep node | grep ${NODE_MAIN} | grep -v grep | awk '{print$2}'`
   
   if [[ ! $checkjavapid ]];then
      echo -e "\rno nodejs process"
      return
   fi

   echo "stop nodejs process"
   times=60
   for e in $(seq 60)
   do
        sleep 1
        COSTTIME=$(($times - $e ))
        checkjavapid=`ps -ef | grep node | grep ${NODE_MAIN} | grep -v grep | awk '{print$2}'`
        if [[ $checkjavapid ]];then
            kill -9 $checkjavapid
            echo -e  "\r        -- stopping node lasts `expr $COSTTIME` seconds."
        else
            echo -e "\node process has exited"
            break;
        fi
   done
   echo ""
}
start() {
    start_application
    health_check
}
stop() {
    stop_application
}
case "$ACTION" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        start
    ;;
    *)
        usage
    ;;
esac