#!/bin/bash
# Config
#用法：bash synctv.sh moem9e9 

afcookie="$AFCOOKIE"
userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
username="$USERNAME"
password="$PASSWORD"
m3u8site="$M3U8SITE"
logfile="log/log_`date '+%Y%m%d'`.txt"
#userIds=$1
userIds="eunyoung1238";
#
#afreeca gusdk2362  sol3712 m0m099  namuh0926 
#pop162cm
#flex golaniyule0
#? lovether

echo -e `date` >> $logfile
userToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' --data-raw "{\"username\": \"${username}\",\"password\": \"${password}\"}" -X POST "${synctv}/api/user/login"|jq -r .data.token`
echo $userToken


unreachableIds=()
#for ((i=1; i<=1000; i++)); do
#    echo "Round $i:"
    for userId in ${userIds}; do
        json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"  "https://bjapi.afreecatv.com/api/{$userId}/station"` 
        BNO=`echo $json| jq -r .broad.broad_no`
        timestamp=$(date +%s)
        img="https://liveimg.afreecatv.com/m/${BNO}?${timestamp}";
        startTime=`echo "$json"|jq .station.broad_start`
        
        echo "开始获取直播源"
        if [ -n "$BNO"  ] &&  [ "$BNO" != null ]; then
            hls_key=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" -H "cookie:${afcookie}" -F bid="${userId}" -F 'type="aid"' 'https://live.afreecatv.com/afreeca/player_live_api.php'| jq -r .CHANNEL.AID`
            hls_url=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" "https://livestream-manager.afreecatv.com/broad_stream_assign.html?return_type=gcp_cdn&broad_key=${BNO}-common-master-hls"|jq -r .view_url`
            hls="${hls_url}?aid=${hls_key}" 
            echo "${userId}获取成功。"
            echo "直播源：${hls}"
            echo "开始创建房间" 
            room=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}" --data-raw "{\"roomName\":\"Panda_${userId}\",\"password\":\"\",\"setting\": {\"hidden\": false}}" -X POST "${synctv}/api/room/create"`
            roomid=`echo $room|jq -r .data.roomId`
            roomToken=`echo $room|jq -r .data.token`
            echo "房间id：$roomid"
            if [ -n "$roomid"  ] && [ "$roomid" != null ]; then
                jsondata="{\"name\": \"${userId}\",\"url\": \"${hls}\",\"type\": \"m3u8\",\"live\": true}"
                #echo -e "$userId $roomid $roomToken $hls">> data.txt
                #echo -e "添加$userId $hls">> $logfile
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} -X POST "${synctv}/api/movie/clear"
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                echo "$userId 已推送到Sync TV, removing from list"
                #text="*J哥提醒你！！！！*\n\nAfreeca主播${userId}直播源已添加到SyncTV\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直播源地址，sync维护！]($hls})\n\n[康康panda！](${m3u8site})\n\n"
                #text=$(echo "${text}" | sed 's/-/\\\\-/g')
                #curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
            elif [ "$roomid" = null ]; then
                echo $room|jq -r .error
                echo "创建房间失败，可能已有同名房间，跳过此ID" 
            else 
                echo "创建房间失败，跳过此ID（错误提示${room}）" 
            fi
            
            if grep -q "${userId}" data.txt; then
                echo "The UID $uid exists in data.txt"
            else
                echo "$userId 已推送到TG"
                #text="*J哥提醒你！！！！*\n\nAfreeca主播${userId}直播源已添加到SyncTV\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${userId})\n\n"
                text="*J哥提醒你！！！！*\n\nAfreeca主播${userId}已在线\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直播源地址]($hls)\n\n[康康pandalive！](${m3u8site})\n\n"
                text=$(echo "${text}" | sed 's/-/\\\\-/g')
                curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
                echo -e "$userId $roomid $roomToken $hls">> data.txt
                echo -e "添加$userId $hls">> $logfile
            fi
            reachableIds+=("$userId")
        else 
            echo "$userId 获取直播源失败！"
            echo "错误提示：$json "
        fi   
        echo "-----------`date`--------------"
        sleep 3
    done   
    #sleep 10    

    # 从原始列表中移除已推送的UserID
    for reachableId in "${reachableIds[@]}"; do
        userIds=${userIds//$reachableId/}
    done

    echo "Remaining UserIds for rechecking: $userIds"

    # 在剩余的UserID中重新检查
    if [ ${#userIds} -eq 0 ]; then
        echo "All UserIds are reachable. Exiting."
        break
    fi
#done
