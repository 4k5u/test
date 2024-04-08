#!/bin/bash
# Config
#用法：bash st.sh Daji-520

userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
username="$USERNAME"
password="$PASSWORD"
m3u8site="$M3U8SITE"
cookie="";
logfile="log/log_`date '+%Y%m%d'`.txt"
#userIds=$1
userIds="M--I--A lucille_evans alicelebel Reaowna Akiyama_Key sigmasian Xenomy TefFfish Sime_Naughty SanySenise _PunPun18 BadAngels666 JP-KARIN 777YikuYiku Hahaha_ha2 Daji-520 San___San mikio_san AkiShina Sherry_niko Lucille_evans morphesoull";

userToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' --data-raw "{\"username\": \"${username}\",\"password\": \"${password}\"}" -X POST "${synctv}/api/user/login"|jq -r .data.token`
echo $userToken

unreachableIds=()
#for ((i=1; i<=1000; i++)); do
#    echo "Round $i:"
    for userId in ${userIds}; do
        json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" -H 'x-device-info:{"t":"webMobile","v":"1.0","ui":24631221}'  "https://zh.stripchat.com/api/front/v2/models/username/${userId}/cam"` 
        sid=`echo $json| jq -r .cam.streamName`
        islive=`echo $json|jq .cam.isCamAvailable`
        imgTimestamp=`echo $json| jq -r .user.user.snapshotTimestamp`
        img="https://img.strpst.com/thumbs/${imgTimestamp}/${sid}_webp"
        echo "${islive}"
        echo "开始获取直播源"
        if [ "${islive}" == true ]; then
            echo "${userId}获取成功。"
            hls="https://edge-hls.doppiocdn.net/hls/${sid}/master/${sid}_auto.m3u8?playlistType=lowLatency"
            echo "直播源：$hls"
            echo "开始创建房间" 
            room=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}" --data-raw "{\"roomName\":\"ST_${userId}\",\"password\":\"\",\"setting\": {\"hidden\": false}}" -X POST "${synctv}/api/room/create"`
            roomid=`echo $room|jq -r .data.roomId`
            roomToken=`echo $room|jq -r .data.token`
            echo "房间id：$roomid"
            if [ -n "$roomid"  ] && [ "$roomid" != null ]; then
                jsondata="{\"name\": \"${userId}\",\"url\": \"${hls}\",\"type\": \"m3u8\",\"live\": true}"
                echo -e "$userId $roomid $roomToken $hls">> data.txt
                echo -e "添加$userId $hls">> $logfile
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} -X POST "${synctv}/api/movie/clear"
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                echo "$userId 已推送到Sync TV, removing from list"
                text="*J哥提醒你！！！！*\n\nStripchat主播${userId}直播源已添加到SyncTV\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${hls})\n\n"
                text=$(echo "${text}" | sed 's/-/\\\\-/g')
                text=$(echo "${text}" | sed 's/_/\\\\_/g')
                curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
            elif [ "$roomid" = null ]; then
                echo $room|jq -r .error
                echo "创建房间失败，可能已有同名房间，跳过此ID" 
            else 
                echo "创建房间失败，跳过此ID（错误提示${room}）" 
            fi
            reachableIds+=("$userId")
        else 
            echo "$userId 获取直播源失败！"
            echo "错误提示：" #$json "
        fi   
        echo "-----------`date`--------------"
        sleep 1
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
echo "开始检测失效房间"
bash check.sh
