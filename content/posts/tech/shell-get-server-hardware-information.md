---
title: "shell | 获取服务器硬件信息（整合为json格式）" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- shell
keywords:
- shell
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---

# 前言

查看硬件信息，并将信息整合成json数值，然后传给前段进行分析，最后再进行相应的处理。在装系统的时候，或是进行监控时，都是一个标准的自动化运维流程。使用shell直接生成好json数据再进行传输，会变得非常方便。

# 环境

```
[root@sys-idc-pxe01 ~]# yum install jq lsscsi MegaCli
```
# 脚本内容

```bash
#!/bin/sh
#description: get server hardware info
#author: lvbibir
#date: 20180122
#需要安装jq工具 yum install jq

#用于存放该服务器的所有信息，个人喜欢把全局变量写到外面
#写到函数里面，没有加local的变量也是全局变量
INFO="{}"

#定义一个工具函数，用于生成json数值，后面将会频繁用到
function create_json()
{
  #utility function
  local key=$1
  local value="$2"
  local json=""

  #if value is string
  if [ -z "$(echo "$value" |egrep "\[|\]|\{|\}")" ]
  then
    json=$(jq -n {"$key":"\"$value\""})
  #if value is json, object
  elif [ "$(echo "$value" |jq -r type)" == "object" ]
  then
    json=$(jq -n {"$key":"$value"})
  #if value is array
  elif [ "$(echo "$value" |jq -r type)" == "array" ]
  then
    json=$(jq -n "{$key:$value}")
  else
    echo "value type error..."
    exit 1
    return 0
  fi
  echo $json
  return 0
}

#获取CPU信息
function get_cpu()
{
  #获取cpu信息，去掉空格和制表符和空行，以便于for循环
  local cpu_model_1=$(dmidecode -s processor-version |grep '@' |tr -d " " |tr -s "\n" |tr -d "\t")
  local cpu_info="{}"
  local i=0

  #因为去掉了空格和制表符，以下默认使用换行符分隔
  for line in $(echo "$cpu_model_1")
  do
    local cpu_model="$line"
    local cpu1=$(create_json "cpu_model" "$cpu_model")
    #获取每块cpu的信息，这里只记录了型号
    local cpu=$(create_json "cpu_$i" "$cpu1")
    local cpu_info=$(jq -n "$cpu_info + $cpu")
    i=$[ $i + 1]
  done

  #将cpu的信息整合成一个json，key是cpu
  local info=$(create_json "cpu" "$cpu_info")
  #将信息加入到全局变量中
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_mem()
{

  #generate json {Locator:{sn:sn,size:size}}
  local mem_info="{}"
  #获取每个内存的信息，包括Size:|Locator:|Serial Number:
  local mem_info_1=$(dmidecode -t memory |egrep 'Size:|Locator:|Serial Number:' |grep -v 'Bank Locator:' |awk '
  {
    if (NR%3==1 && $NF=="MB")
    {
      size=$2;
      getline (NR+1);
      locator=$2;
      getline (NR+2);
      sn=$NF;
      printf("%s,%s,%s\n",locator,size,sn)
    }
  }')

  #根据上面的信息，将信息过滤并整合成json
  local i=0
  for line in $(echo "$mem_info_1")
  do
    local locator=$(echo $line |awk -F , '{print $1}')
    local      sn=$(echo $line |awk  -F , '{print $3}')
    local    size=$(echo $line |awk -F , '{print $2}')

    local mem1=$(create_json "locator" "$locator")
    local mem2=$(create_json "sn" "$sn")
    local mem3=$(create_json "size" "$size")
    local mem4=$(jq -n "$mem1 + $mem2 + $mem3")
    #每条内存的信息，key是内存从0开始的序号
    local mem=$(create_json "mem_$i" "$mem4")
    #将这些内存的信息组合到一个json中
    mem_info=$(jq -n "$mem_info + $mem")
    i=$[ $i + 1 ]
  done

  #给这些内存的信息设置key，mem
  local info=$(create_json "mem" "$mem_info")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_megacli_disk()
{
  #设置megacli工具的路径，此条可以根据情况更改
  local raid_tool="/opt/MegaRAID/MegaCli/MegaCli64"
  #将硬盘信息获取，保存下来，省去每次都执行的操作
  $raid_tool pdlist aall >/tmp/megacli_pdlist.txt

  local disk_info="{}"
  #获取硬盘的必要信息
  local disk_info_1=$(cat /tmp/megacli_pdlist.txt |egrep 'Enclosure Device ID:|Slot Number:|PD Type:|Raw Size:|Inquiry Data:|Media Type:'|awk '
{
  if(NR%6==1 && $1$2=="EnclosureDevice")
  {
    E=$NF;
    getline (NR+1);
    S=$NF;
    getline (NR+2);
    pdtype=$NF;
    getline (NR+3);
    size=$3$4;
    getline (NR+4);
    sn=$3$4$5$6;
    getline (NR+5);
    mediatype=$3$4$5$6;
    printf("%s,%s,%s,%s,%s,%s\n",E,S,pdtype,size,sn,mediatype)
  }
}')

  #将获取到的硬盘信息进行整合，生成json
  local i=0
  for line in $(echo $disk_info_1)
  do
    #local       key=$(echo $line |awk -F , '{printf("ES%s_%s\n",$1,$2)}')
    local         E=$(echo $line |awk -F , '{print $1}')
    local         S=$(echo $line |awk -F , '{print $2}')
    local    pdtype=$(echo $line |awk -F , '{print $3}')
    local      size=$(echo $line |awk -F , '{print $4}')
    local        sn=$(echo $line |awk -F , '{print $5}')
    local mediatype=$(echo $line |awk -F , '{print $6}')

    local disk1=$(create_json "pdtype" "$pdtype")
    local disk1_1=$(create_json "enclosure_id" "$E")
    local disk1_2=$(create_json "slot_id" "$S")
    local disk2=$(create_json "size" "$size")
    local disk3=$(create_json "sn" "$sn")
    local disk4=$(create_json "mediatype" "$mediatype")
    local disk5=$(jq -n "$disk1 + $disk1_1 + $disk1_2 + $disk2 + $disk3 + $disk4")
    local disk=$(create_json "disk_$i" "$disk5")
    disk_info=$(jq -n "$disk_info + $disk")
    i=$[ $i + 1 ]
  done
  #echo $disk_info
  local info=$(create_json "disk" "$disk_info")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_hba_disk()
{
  #对于hba卡的硬盘，使用smartctl获取硬盘信息
  local disk_tool="smartctl"
  local disk_info="{}"
  #lsscsi 需要使用yum install lsscsi 安装
  local disk_info_1=$(lsscsi -g |grep -v 'enclosu' |awk '{printf("%s,%s,%s,%s\n",$1,$2,$(NF-1),$NF)}')
  local i=0
  for line in $(echo $disk_info_1)
  do
    local         E=$(echo $line |awk -F , '{print $1}' |awk -F ':' '{print $1}' |tr -d '\[|\]')
    local         S=$(echo $line |awk -F , '{print $NF}' |egrep -o [0-9]*)
    local        sd=$(echo $line |awk -F , '{print $(NF-1)}')
    $disk_tool -i $sd >/tmp/disk_info.txt
    local    pdtype="SATA"
    if [ "$(cat /tmp/disk_info.txt |grep 'Transport protocol:' |awk '{print $NF}')" == "SAS" ]
    then
    local    pdtype="SAS"
    fi
    local      size=$(cat /tmp/disk_info.txt |grep 'User Capacity:' |awk '{printf("%s%s\n",$(NF-1),$NF)}' |tr -d '\[|\]')
    local        sn=$(cat /tmp/disk_info.txt |grep 'Serial Number:' |awk '{print $NF}')
    local mediatype="disk"

    local disk1=$(create_json "pdtype" "$pdtype")
    local disk1_1=$(create_json "enclosure_id" "$E")
    local disk1_2=$(create_json "slot_id" "$S")
    local disk2=$(create_json "size" "$size")
    local disk3=$(create_json "sn" "$sn")
    local disk4=$(create_json "mediatype" "$mediatype")
    local disk5=$(jq -n "$disk1 + $disk1_1 + $disk1_2 + $disk2 + $disk3 + $disk4")
    local disk=$(create_json "disk_$i" "$disk5")
    disk_info=$(jq -n "$disk_info + $disk")
    i=$[ $i + 1 ]
  done
  #echo $disk_info
  local info=$(create_json "disk" "$disk_info")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_disk()
{
  #根据获取到的硬盘控制器类型，来判断使用什么工具采集硬盘信息
  if [ "$(echo "$INFO" |jq -r .disk_ctrl.disk_ctrl_0.type)" == "raid" ]
  then
    get_megacli_disk
  elif [ "$(echo "$INFO" |jq -r .disk_ctrl.disk_ctrl_0.type)" == "hba" ]
  then
    get_hba_disk
  else
    local info=$(create_json "disk" "error")
    INFO=$(jq -n "$INFO + $info")
  fi
  #hp机器比较特殊，这里我没有做hp机器硬盘信息采集，有兴趣的朋友可以自行添加上
  #if hp machine

  return 0
}

function get_diskController()
{
  local disk_ctrl="{}"
  #if LSI Controller
  local disk_ctrl_1="$(lspci -nn |grep LSI)"
  local i=0

  #以换行符分隔
  IFS_OLD=$IFS && IFS=$'\n'
  for line in $(echo "$disk_ctrl_1")
  do
    #echo $line
    local   ctrl_id=$(echo "$line" |awk -F ']:' '{print $1}' |awk '{print $NF}' |tr -d '\[|\]')

    case "$ctrl_id" in
    #根据控制器的id或进行判断是raid卡还是hba卡，因为品牌比较多，后续可以在此处进行扩展添加
    0104)
      # 获取Logic以后的字符串，并进行拼接
      local ctrl_name=$(echo "${line##*"Logic"}" |awk '{printf("%s_%s_%s\n",$1,$2,$3)}')
      local     ctrl1=$(create_json "id" "$ctrl_id")
      local     ctrl2=$(create_json "type" "raid")
      local     ctrl3=$(create_json "name" "$ctrl_name")
      ;;
    0100|0107)
      local ctrl_name=$(echo "${line##*"Logic"}" |awk '{printf("%s_%s_%s\n",$1,$3,$4)}')
      local     ctrl1=$(create_json "id" "$ctrl_id")
      local     ctrl2=$(create_json "type" "hba")
      local     ctrl3=$(create_json "name" "$ctrl_name")
      ;;
    *)
      local     ctrl1=$(create_json "id" "----")
      local     ctrl2=$(create_json "type" "----")
      local     ctrl3=$(create_json "name" "----")
      ;;
    esac
    local ctrl_tmp=$(jq -n "$ctrl1 + $ctrl2 + $ctrl3")
    local ctrl=$(create_json "disk_ctrl_$i" "$ctrl_tmp")
    disk_ctrl=$(jq -n "$disk_ctrl + $ctrl")
    i=$[ $i + 1 ]
  done
  IFS=$IFS_OLD
  local info=$(create_json "disk_ctrl" "$disk_ctrl")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_netcard()
{
  local netcard_info="{}"
  local netcard_info_1="$(lspci -nn |grep Ether)"
  local i=0
  #echo "$netcard_info_1"
  IFS_OLD=$IFS && IFS=$'\n'
  for line in $(echo "$netcard_info_1")
  do
    local     net_id=$(echo $line |egrep -o '[0-9a-z]{4}:[0-9a-z]{4}')
    local   net_id_1=$(echo $net_id |awk -F : '{print $1}')

    case "$net_id_1" in
    8086)
      local net_name=$(echo "${line##*": "}" |awk '{printf("%s_%s_%s_%s\n",$1,$3,$4,$5)}')
      local     type=$(echo $line |egrep -o SFP || echo "TP")
      local     net1=$(create_json "id" "$net_id")
      local     net2=$(create_json "name" "$net_name")
      local     net3=$(create_json "type" "$type")
      ;;
    14e4)
      local net_name=$(echo "${line##*": "}" |awk '{printf("%s_%s_%s_%s\n",$1,$3,$4,$5)}')
      local     type=$(echo $line |egrep -o SFP || echo "TP")
      local     net1=$(create_json "id" "$net_id")
      local     net2=$(create_json "name" "$net_name")
      local     net3=$(create_json "type" "$type")
      ;;
    *)
      local net_name=$(echo "${line##*": "}" |awk '{printf("%s_%s_%s_%s\n",$1,$3,$4,$5)}')
      local     type=$(echo $line |egrep -o SFP || echo "TP")
      local     net1=$(create_json "id" "$net_id")
      local     net2=$(create_json "name" "$net_name")
      local     net3=$(create_json "type" "$type")
      ;;
    esac

    local net1=$(jq -n "$net1 + $net2 + $net3")
    #echo $net
    local net2=$(create_json "net_$i" "$net1")
    netcard_info=$(jq -n "$netcard_info + $net2")
    i=$[ $i + 1 ]

  done
  IFS=$IFS_OLD
  local info=$(create_json "net" "$netcard_info")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

function get_server()
{
  local product=$(dmidecode -s system-product-name |grep -v '^#' |tr -d ' ' |head -n1)
  local manufacturer=$(dmidecode -s system-manufacturer |grep -v '^#' |tr -d ' ' |head -n1)
  local server1=$(create_json "manufacturer" "$manufacturer")
  local server2=$(create_json "product" "$product")
  local server3=$(jq -n "$server1 + $server2")
  local info=$(create_json "basic_info" "$server3")
  INFO=$(jq -n "$INFO + $info")

  return 0
}

ALL_INFO=""
function get_all()
{
  #因为硬盘信息的获取依赖硬盘控制器的信息，所以get_diskController要放到get_disk前面
  get_server
  get_cpu
  get_mem
  get_diskController
  get_disk
  get_netcard

  local sn=$(dmidecode -s system-serial-number |grep -v '^#' |tr -d ' ' |head -n1)
  ALL_INFO=$(create_json "$sn" "$INFO")
  return 0
}

function main()
{
  get_all
  echo $ALL_INFO
  return 0
}

#-------------------------------------------------
main
```