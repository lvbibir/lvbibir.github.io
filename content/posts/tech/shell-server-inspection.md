---
title: "shell | 服务器巡检脚本" 
date: 2021-09-01
lastmod: 2021-09-01
tags: 
- shell
- linux
keywords:
- shell
- linux
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---

代码如下

```bash
#!/bin/bash
#参数定义
date=`date +"%Y-%m-%d-%H:%M:%S"`
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION=`date +%F`
#日志相关
LOGPATH="/tmp/awr"
[ -e $LOGPATH ] || mkdir -p $LOGPATH
RESULTFILE="$LOGPATH/HostCheck-`hostname`-`date +%Y%m%d`.txt"

#调用函数库
[ -f /etc/init.d/functions ] && source /etc/init.d/functions
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile


#root用户执行脚本
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1

 
function version(){
    echo ""
    echo ""
    echo "[${date}] >>> `hostname -s` 主机巡检"
}


function getSystemStatus(){
    echo ""
    echo -e "\033[33m****************************************************系统检查****************************************************\033[0m"
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo "     系统：$OS"
    echo " 发行版本：$Release"
    echo "     内核：$Kernel"
    echo "   主机名：$Hostname"
    echo "  SELinux：$SELinux"
    echo "语言/编码：$default_LANG"
    echo " 当前时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
    export LANG="$default_LANG"
}

function getCpuStatus(){
    echo ""
    echo -e "\033[33m****************************************************CPU检查*****************************************************\033[0m"
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
    echo "物理CPU个数:$Physical_CPUs"
    echo "逻辑CPU个数:$Virt_CPUs"
    echo "每CPU核心数:$CPU_Kernels"
    echo "    CPU型号:$CPU_Type"
    echo "    CPU架构:$CPU_Arch"
}

function getMemStatus(){
    echo ""
    echo  -e "\033[33m**************************************************内存检查*****************************************************\033[0m"
    if [[ $centosVersion < 7 ]];then
        free -mo
    else
        free -h
    fi
    #报表信息
    MemTotal=$(grep MemTotal /proc/meminfo| awk '{print $2}')  #KB
    MemFree=$(grep MemFree /proc/meminfo| awk '{print $2}')    #KB
    let MemUsed=MemTotal-MemFree
    MemPercent=$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}") 
}

function getDiskStatus(){
    echo ""
    echo -e "\033[33m**************************************************磁盘检查******************************************************\033[0m"
    df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
    df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk 
    join /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$8,$9,$10,$11,"|",$12}'| column -t
    #报表信息
    diskdata=$(df -TP | sed '1d' | awk '$2!="tmpfs"{print}') #KB
    disktotal=$(echo "$diskdata" | awk '{total+=$3}END{print total}') #KB
    diskused=$(echo "$diskdata" | awk '{total+=$4}END{print total}')  #KB
    diskfree=$((disktotal-diskused)) #KB
    diskusedpercent=$(echo $disktotal $diskused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}') 
    inodedata=$(df -iTP | sed '1d' | awk '$2!="tmpfs"{print}')
    inodetotal=$(echo "$inodedata" | awk '{total+=$3}END{print total}')
    inodeused=$(echo "$inodedata" | awk '{total+=$4}END{print total}')
    inodefree=$((inodetotal-inodeused))
    inodeusedpercent=$(echo $inodetotal $inodeused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
}



function get_resource(){
    echo ""
    echo -e "\033[33m**************************************************资源消耗统计**************************************************\033[0m"

    echo -e "\033[36m*************带宽资源消耗统计*************\033[0m"
	#用数组存放网卡名
    nic=(`ifconfig | grep ^[a-z] | grep -vE 'lo|docker0'| awk -F: '{print $1}'`)
	time=`date "+%Y-%m-%d %k:%M"`
	num=0
	
    for ((i=0;i<${#nic[@]};i++))
	do
	   #循环五次，避免看到的是偶然的数据
       while (( $num<5 ))
	   do
	     rx_before=$(cat /proc/net/dev | grep '${nic[$i]}' | tr : " " | awk '{print $2}')
         tx_before=$(cat /proc/net/dev | grep '${nic[$i]}' | tr : " " | awk '{print $10}')
		 sleep 2
		 #用sed先获取第7列,再用awk获取第2列，再cut切割,从第7个到最后，即只切割网卡流量数字部分
         rx_after=$(cat /proc/net/dev | grep '${nic[$i]}' | tr : " " | awk '{print $2}')
         tx_after=$(cat /proc/net/dev | grep '${nic[$i]}' | tr : " " | awk '{print $10}')
		 #注意下面截取的相差2秒的两个时刻的累计和发送的bytes(即累计传送和接收的位)
         rx_result=$[(rx_after-rx_before)/1024/1024/2*8]
         tx_result=$[(tx_after-tx_before)/1024/1024/2*8]
		 echo  "$time Now_In_Speed: $rx_result Mbps  Now_OUt_Speed: $tx_result Mbps" >> /tmp/network.txt
		 let "num++"
	   done
	   #注意下面grep后面的$time变量要用双引号括起来
       rx_result=$(cat /tmp/network.txt|grep "$time"|awk '{In+=$4}END{print In}')
       tx_result=$(cat /tmp/network.txt|grep "$time"|awk '{Out+=$7}END{print Out}')
       In_Speed=$(echo "scale=2;$rx_result/5"|bc)
       Out_Speed=$(echo "scale=2;$tx_result/5"|bc)
       echo -e  "\033[32m In_Speed_average: $In_Speed Mbps Out_Speed_average: $Out_Speed Mbps! \033[0m" 
	done


    echo -e "\033[36m*************CPU资源消耗统计*************\033[0m"

    #使用vmstat 1 5命令统计5秒内的使用情况，再计算每秒使用情况
	total=`vmstat 1 5|awk '{x+=$13;y+=$14}END{print x+y}'`
	cpu_average=$(echo "scale=2;$total/5"|bc)
	
	#判断CPU使用率（浮点数与整数比较）
	if [ `echo "${cpu_average} > 70" | bc` -eq 1 ];then
	    echo -e  "\033[31m Total CPU is already use: ${cpu_average}%,请及时处理！\033[0m" 
    else 
	    echo -e  "\033[32m Total CPU is already use: ${cpu_average}%! \033[0m" 
    fi


    echo -e "\033[36m*************磁盘资源消耗统计*************\033[0m"
    #磁盘使用情况(注意：需要用sed先进行格式化才能进行累加处理)
    disk_used=$(df -m | sed '1d;/ /!N;s/\n//;s/ \+/ /;' | awk '{used+=$3} END{print used}')
    disk_totalSpace=$(df -m | sed '1d;/ /!N;s/\n//;s/ \+/ /;' | awk '{totalSpace+=$2} END{print totalSpace}')
    disk_all=$(echo "scale=4;$disk_used/$disk_totalSpace" | bc)
    disk_percent1=$(echo $disk_all | cut -c 2-3)
    disk_percent2=$(echo $disk_all | cut -c 4-5)
    disk_warning=`df -m | sed '1d;/ /!N;s/\n//;s/ \+/ /;' | awk '{if ($5>85) print $6 "目录使用率：" $5;} '`
    
	echo -e  "\033[32m Total disk has used: $disk_percent1.$disk_percent2% \033[0m" 
    #echo -e "\t\t.." 表示换行
	if [ -n  "$disk_warning" ];then
	    echo -e "\033[31m${disk_warning} \n [Error]以上目录使用率超过85%，请及时处理！\033[0m" 
	fi
	
    echo -e "\033[36m*************内存资源消耗统计*************\033[0m"
	
    #获得系统总内存
	memery_all=$(free -m | awk 'NR==2' | awk '{print $2}')
	#获得占用内存（操作系统 角度）
	system_memery_used=$(free -m | awk 'NR==2' | awk '{print $3}')
	#获得buffer、cache占用内存，当内存不够时会及时回收，所以这两部分可用于可用内存的计算
	buffer_used=$(free -m | awk 'NR==2' | awk '{print $6}')
	cache_used=$(free -m | awk 'NR==2' | awk '{print $7}')
	#获得被使用内存，所以这部分可用于可用内存的计算，注意计算方法
	actual_used_all=$[memery_all-(free+buffer_used+cache_used)]
	#获得实际占用的内存
	actual_used_all=`expr $memery_all - $free + $buffer_used + $cache_used `
    memery_percent=$(echo "scale=4;$system_memery_used / $memery_all" | bc)
    memery_percent2=$(echo "scale=4; $actual_used_all / $memery_all" | bc)
    percent_part1=$(echo $memery_percent | cut -c 2-3)
    percent_part2=$(echo $memery_percent | cut -c 4-5)
    percent_part11=$(echo $memery_percent2 | cut -c 2-3)
    percent_part22=$(echo $memery_percent2 | cut -c 4-5)
    
	#获得占用内存（操作系统角度）
    echo -e "\033[32m system memery is already use: $percent_part1.$percent_part2% \033[0m"
    #获得实际内存占用率
    echo -e "\033[32m actual memery is already use: $percent_part11.$percent_part22% \033[0m"
    echo -e "\033[32m buffer is already used : $buffer_used M \033[0m"
    echo -e "\033[32m cache is already used : $cache_used M \033[0m"
}



function getServiceStatus(){
    echo ""
    echo -e "\033[33m*************************************************服务检查*******************************************************\033[0m"
    echo ""
    if [[ $centosVersion > 7 ]];then
        conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
        process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")      
    else
        conf=$(/sbin/chkconfig | grep -E ":on|:启用")
        process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")        
    fi
	echo -e "\033[36m******************服务配置******************\033[0m"
    echo "$conf"  | column -t
    echo ""
	echo -e "\033[36m**************正在运行的服务****************\033[0m"
    echo "$process"
}


function getAutoStartStatus(){
    echo ""
    echo -e "\033[33m***********************************************自启动检查*******************************************************\033[0m"
    echo -e "\033[36m****************自启动命令*****************\033[0m"
	conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
    echo "$conf"  
}


function getLoginStatus(){
    echo ""
    echo -e "\033[33m************************************************登录检查********************************************************\033[0m"
    last | head 
}

function getNetworkStatus(){
    echo ""
    echo -e "\033[33m************************************************网络检查********************************************************\033[0m"
    if [[ $centosVersion < 7 ]];then
        /sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v i
		net6
    else
        #ip a
        for i in $(ip link | grep BROADCAST | awk -F: '{print $2}');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' ;echo "" ;done
    fi
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo ""
    echo "网关：$GATEWAY "
    echo "DNS：$DNS"
    #报表信息
    IP=$(ip -f inet addr | grep -v 127.0.0.1 |  grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
    MAC=$(ip link | grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
    echo ""
ping -c 4 www.baidu.com >/dev/null 2>&1
if [ $? -eq 0 ];then
   echo ""
   echo -e "\033[32m网络连接：正常！\033[0m" 
else
   echo ""
   echo -e "\033[31m网络连接：异常！\033[0m" 
fi 
}


function getListenStatus(){
    echo ""
    echo  -e "\033[33m***********************************************监听检查********************************************************\033[0m"
    TCPListen=$(ss -ntul | column -t)
    echo "$TCPListen"
}


function getCronStatus(){
    echo ""
    echo -e "\033[33m**********************************************计划任务检查******************************************************\033[0m"
    Crontab=0
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            crontab -l -u $user >/dev/null 2>&1
            status=$?
            if [ $status -eq 0 ];then
                echo -e "\033[36m************$user用户的定时任务**************\033[0m"
                crontab -l -u $user
                let Crontab=Crontab+$(crontab -l -u $user | wc -l)
                echo ""
            fi
        done
    done
    #计划任务
    #find /etc/cron* -type f | xargs -i ls -l {} | column  -t
    #let Crontab=Crontab+$(find /etc/cron* -type f | wc -l) 
}


function getHowLongAgo(){
    # 计算一个时间戳离现在有多久了
    datetime="$*"
    [ -z "$datetime" ] && echo `stat /etc/passwd|awk "NR==6"`
    Timestamp=$(date +%s -d "$datetime")  
    Now_Timestamp=$(date +%s)
    Difference_Timestamp=$(($Now_Timestamp-$Timestamp))
    days=0;hours=0;minutes=0;
    sec_in_day=$((60*60*24));
    sec_in_hour=$((60*60));
    sec_in_minute=60
    while (( $(($Difference_Timestamp-$sec_in_day)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_day
        let days++
    done
    while (( $(($Difference_Timestamp-$sec_in_hour)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_hour
        let hours++
    done
    echo "$days 天 $hours 小时前"
}


function getUserLastLogin(){
    # 获取用户最近一次登录的时间，含年份
    # 很遗憾last命令不支持显示年份，只有"last -t YYYYMMDDHHMMSS"表示某个时间之间的登录，我
    # 们只能用最笨的方法了，对比今天之前和今年元旦之前（或者去年之前和前年之前……）某个用户
    # 登录次数，如果登录统计次数有变化，则说明最近一次登录是今年。
    username=$1
    : ${username:="`whoami`"}
    thisYear=$(date +%Y)
    oldesYear=$(last | tail -n1 | awk '{print $NF}')
    while(( $thisYear >= $oldesYear));do
        loginBeforeToday=$(last $username | grep $username | wc -l)
        loginBeforeNewYearsDayOfThisYear=$(last $username -t $thisYear"0101000000" | grep $username | wc -l)
        if [ $loginBeforeToday -eq 0 ];then
            echo "从未登录过"
            break
        elif [ $loginBeforeToday -gt $loginBeforeNewYearsDayOfThisYear ];then
            lastDateTime=$(last -i $username | head -n1 | awk '{for(i=4;i<(NF-2);i++)printf"%s ",$i}')" $thisYear" 
            lastDateTime=$(date "+%Y-%m-%d %H:%M:%S" -d "$lastDateTime")
            echo "$lastDateTime"
            break
        else
            thisYear=$((thisYear-1))
        fi
    done
}


function getUserStatus(){
    echo ""
    echo -e "\033[33m*************************************************用户检查*******************************************************\033[0m"
    #/etc/passwd 最后修改时间
    pwdfile="$(cat /etc/passwd)"
    Modify=$(stat /etc/passwd | grep Modify | tr '.' ' ' | awk '{print $2,$3}')
    echo "/etc/passwd: $Modify ($(getHowLongAgo $Modify))"
    echo ""
    echo -e "\033[36m******************特权用户******************\033[0m"
    RootUser=""
    for user in $(echo "$pwdfile" | awk -F: '{print $1}');do
        if [ $(id -u $user) -eq 0 ];then
            echo "$user"
            RootUser="$RootUser,$user"
        fi
    done
    echo ""
	echo -e "\033[36m******************用户列表******************\033[0m"
    USERs=0
    echo "$(
    echo "用户名 UID GID HOME SHELL 最后一次登录"
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for username in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            userLastLogin="$(getUserLastLogin $username)"
            echo "$pwdfile" | grep -w "$username" |grep -w "$shell"| awk -F: -v lastlogin="$(echo "$userLastLogin" | tr ' ' '_')" '{print $1,$3,$4,$6,$7,lastlogin}'
        done
        let USERs=USERs+$(echo "$pwdfile" | grep "$shell"| wc -l)
    done
    )" | column -t
    echo ""
	echo -e "\033[36m******************空密码用户****************\033[0m"
    USEREmptyPassword=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
            for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            r=$(awk -F: '$2=="!!"{print $1}' /etc/shadow | grep -w $user)
            if [ ! -z $r ];then
                echo $r
                USEREmptyPassword="$USEREmptyPassword,"$r
            fi
        done    
    done
    echo ""
	echo -e "\033[36m*****************相同ID用户*****************\033[0m"
    USERTheSameUID=""
    UIDs=$(cut -d: -f3 /etc/passwd | sort | uniq -c | awk '$1>1{print $2}')
    for uid in $UIDs;do
        echo -n "$uid";
        USERTheSameUID="$uid"
        r=$(awk -F: 'ORS="";$3=='"$uid"'{print ":",$1}' /etc/passwd)
        echo "$r"
        echo ""
        USERTheSameUID="$USERTheSameUID $r,"
    done 
}


function getPasswordStatus {
    echo ""
    echo -e "\033[33m*************************************************密码检查*******************************************************\033[0m"
    pwdfile="$(cat /etc/passwd)"
    echo ""
    echo -e "\033[36m****************密码过期检查****************\033[0m"
    result=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            get_expiry_date=$(/usr/bin/chage -l $user | grep 'Password expires' | cut -d: -f2)
            if [[ $get_expiry_date = ' never' || $get_expiry_date = 'never' ]];then
                printf "%-15s 永不过期\n" $user
                result="$result,$user:never"
            else
                password_expiry_date=$(date -d "$get_expiry_date" "+%s")
                current_date=$(date "+%s")
                diff=$(($password_expiry_date-$current_date))
                let DAYS=$(($diff/(60*60*24)))
                printf "%-15s %s天后过期\n" $user $DAYS
                result="$result,$user:$DAYS days"
            fi
        done
    done
    report_PasswordExpiry=$(echo $result | sed 's/^,//')
    echo ""
	echo -e "\033[36m****************密码策略检查****************\033[0m"
    grep -v "#" /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE"
}


function getSudoersStatus(){
    echo ""
    echo -e "\033[33m**********************************************Sudoers检查*******************************************************\033[0m"
    conf=$(grep -v "^#" /etc/sudoers| grep -v "^Defaults" | sed '/^$/d')
    echo "$conf"
    echo ""
}


function getInstalledStatus(){
    echo ""
    echo -e "\033[33m*************************************************软件检查*******************************************************\033[0m"
    rpm -qa --last | head | column -t 
}


function getProcessStatus(){
    echo ""
    echo -e "\033[33m*************************************************进程检查*******************************************************\033[0m"
    if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
        echo ""
        echo -e "\033[36m***************僵尸进程***************\033[0m"
        ps -ef | head -n1
        ps -ef | grep defunct | grep -v grep
    fi
	echo ""
    echo -e "\033[36m************CPU占用TOP 10进程*************\033[0m"
    echo -e "用户 进程ID %CPU 命令 
	$(ps aux | awk '{print $1, $2, $3, $11}' | sort -k3rn | head -n 10 )"| column -t 
    echo ""
    echo -e "\033[36m************内存占用TOP 10进程*************\033[0m"
    echo -e "用户 进程ID %MEM 虚拟内存  常驻内存 命令 
	$(ps aux | awk '{print $1, $2, $4, $5, $6, $11}' | sort -k3rn | head -n 10 )"| column -t 
	#echo ""
    #echo -e "\033[36m************SWAP占用TOP 10进程*************\033[0m"
	#awk: fatal: cannot open file `/proc/18713/smaps' for reading (No such file or directory)
	#for i in `cd /proc;ls |grep "^[0-9]"|awk ' $0 >100'`;do awk '{if (-f /proc/$i/smaps) print "$i file is not exist"; else print "$i"}';done
	#    for i in `cd /proc;ls |grep "^[0-9]"|awk ' $0 >100'` ;do awk '/Swap:/{a=a+$2}END{print '"$i"',a/1024"M"}' /proc/$i/smaps ;done |sort -k2nr > /tmp/swap.txt
	#echo -e "进程ID SWAP使用 $(cat /tmp/swap.txt|grep -v awk | head -n 10)"| column -t
}



function getSyslogStatus(){
    echo ""
    echo -e "\033[33m***********************************************syslog检查*******************************************************\033[0m"
    echo "SYSLOG服务状态：$(getState rsyslog)"
    echo ""
    echo -e "\033[36m***************rsyslog配置******************\033[0m"
    cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^\\$" | sed '/^$/d'  | column -t
}


function getFirewallStatus(){
    echo ""
    echo -e "\033[33m***********************************************防火墙检查*******************************************************\033[0m"

    echo -e "\033[36m****************防火墙状态******************\033[0m"
    if [[ $centosVersion = 7 ]];then
        systemctl status firewalld >/dev/null  2>&1
        status=$?
        if [ $status -eq 0 ];then
                s="active"
        elif [ $status -eq 3 ];then
                s="inactive"
        elif [ $status -eq 4 ];then
                s="permission denied"
        else
                s="unknown"
        fi
    else
        s="$(getState iptables)"
    fi
    echo "firewalld: $s"
    echo ""
    echo -e "\033[36m****************防火墙配置******************\033[0m"
    cat /etc/sysconfig/firewalld 2>/dev/null
}


function getSNMPStatus(){
    #SNMP服务状态，配置等
    echo ""
    echo -e "\033[33m***********************************************SNMP检查*********************************************************\033[0m"
    status="$(getState snmpd)"
    echo "SNMP服务状态：$status"
    echo ""
    if [ -e /etc/snmp/snmpd.conf ];then
        echo "/etc/snmp/snmpd.conf"
        echo "--------------------"
        cat /etc/snmp/snmpd.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
    fi
}


function getState(){
    if [[ $centosVersion < 7 ]];then
        if [ -e "/etc/init.d/$1" ];then
            if [ `/etc/init.d/$1 status 2>/dev/null | grep -E "is running|正在运行" | wc -l` -ge 1 ];then
                r="active"
            else
                r="inactive"
            fi
        else
            r="unknown"
        fi
    else
        #CentOS 7+
        r="$(systemctl is-active $1 2>&1)"
    fi
    echo "$r"
}


function getSSHStatus(){
    #SSHD服务状态，配置,受信任主机等
    echo ""
    echo -e "\033[33m************************************************SSH检查*********************************************************\033[0m"
    #检查受信任主机
    pwdfile="$(cat /etc/passwd)"
    echo "SSH服务状态：$(getState sshd)"
    Protocol_Version=$(cat /etc/ssh/sshd_config | grep Protocol | awk '{print $2}')
    echo "SSH协议版本：$Protocol_Version"
    echo ""
    echo -e "\033[36m****************信任主机******************\033[0m"
    authorized=0
    for user in $(echo "$pwdfile" | grep /bin/bash | awk -F: '{print $1}');do
        authorize_file=$(echo "$pwdfile" | grep -w $user | awk -F: '{printf $6"/.ssh/authorized_keys"}')
        authorized_host=$(cat $authorize_file 2>/dev/null | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')
        if [ ! -z $authorized_host ];then
            echo "$user 授权 \"$authorized_host\" 无密码访问"
        fi
        let authorized=authorized+$(cat $authorize_file 2>/dev/null | awk '{print $3}'|wc -l)
    done
    echo ""
    echo -e "\033[36m*******是否允许ROOT远程登录***************\033[0m"
    config=$(cat /etc/ssh/sshd_config | grep PermitRootLogin)
    firstChar=${config:0:1}
    if [ $firstChar == "#" ];then
        PermitRootLogin="yes" 
    else
        PermitRootLogin=$(echo $config | awk '{print $2}')
    fi
    echo "PermitRootLogin $PermitRootLogin"
    echo ""
    echo -e "\033[36m*************ssh服务配置******************\033[0m"
    cat /etc/ssh/sshd_config | grep -v "^#" | sed '/^$/d'
}


function getNTPStatus(){
    #NTP服务状态，当前时间，配置等
    echo ""
    echo -e "\033[33m***********************************************NTP检查**********************************************************\033[0m"
    if [ -e /etc/ntp.conf ];then
        echo "NTP服务状态：$(getState ntpd)"
        echo ""
        echo -e "\033[36m*************NTP服务配置******************\033[0m"
        cat /etc/ntp.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
    fi
}


function check(){
    version
    getSystemStatus
	get_resource
    getCpuStatus
    getMemStatus
    getDiskStatus
    getNetworkStatus
    getListenStatus
    getProcessStatus
    getServiceStatus
    getAutoStartStatus
    getLoginStatus
    getCronStatus
    getUserStatus
    getPasswordStatus
    getSudoersStatus
    getFirewallStatus
    getSSHStatus
    getSyslogStatus
    getSNMPStatus
    getNTPStatus
    getInstalledStatus
}
#执行检查并保存检查结果
check > $RESULTFILE
echo -e "\033[44;37m 主机巡检结果存放在：$RESULTFILE   \033[0m"

#上传检查结果的文件
#curl -F "filename=@$RESULTFILE" "$uploadHostDailyCheckApi" 2>/dev/null
cat $RESULTFILE
```

