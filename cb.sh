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
userIds="taitehambelton amilia4u gina_gracia _marydel_ Northern_gracia joysuniverse ad0res techofoxxx jiso-baobei oki_dokie galantini _meganmeow_ ake_mi oda_assuri iminako mode_bad intim_mate cuddles_me mazzanti_ honey_pinkgreen sexygamesx foxylovesyou kiriko_chan kiyoko_rin my_eyes_higher _katekeep your_desssert";

userToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' --data-raw "{\"username\": \"${username}\",\"password\": \"${password}\"}" -X POST "${synctv}/api/user/login"|jq -r .data.token`
echo $userToken
echo $(curl ip.sb)
unreachableIds=()
#for ((i=1; i<=1000; i++)); do
#    echo "Round $i:"
    for userId in ${userIds}; do
        http_code=`curl -sSL -w "%{http_code}" -o /dev/null --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" https://jpeg.live.mmcdn.com/stream?room=${userId}`
        if [ "${http_code}" == 200 ]; then
            echo "开始获取直播源"
#            json=`curl --location 'https://cbcb.gds.workers.dev/https://chaturbate.com/get_edge_hls_url_ajax/' --header 'x-requested-with: XMLHttpRequest' --form 'room_slug="${userId}"'`
            #echo $(curl "https://chaturbate.com//streamapi/?modelname=${userId}")
            #json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" "https://proxy.scrapeops.io/v1/?api_key=b3db67ba-385b-4f20-a1ea-4463df5ab939&url=https://chaturbate.com.tw/streamapi/?modelname=${userId}"` 
             json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" "https://chaturbate.com.tw/streamapi/?modelname=${userId}"`
            hls=`echo $json|jq -r .url`
            #img="https://cbjpeg.stream.highwebmedia.com/stream?room=${userId}&f=$(date '+%Y%m%d%H%M')"
            img="https://jpeg.live.mmcdn.com/stream?room=${userId}&f=$(date '+%Y%m%d%H%M')"
            if [ -n "$hls"  ] &&  [ "$hls" != null ]; then
                echo "${userId}获取成功。"
                echo "直播源：${hls}"
                echo "开始创建房间" 
                room=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}" --data-raw "{\"roomName\":\"CB_${userId}\",\"password\":\"\",\"setting\": {\"hidden\": false}}" -X POST "${synctv}/api/room/create"`
                roomid=`echo $room|jq -r .data.roomId`
                roomToken=`echo $room|jq -r .data.token`
                echo "房间id：$roomid"
                if [ -n "$roomid"  ] && [ "$roomid" != null ]; then
                    jsondata="{\"name\": \"${userId}\",\"url\": \"${hls}\",\"type\": \"m3u8\",\"live\": true}"
                    #echo -e "$userId $roomid $roomToken $hls">> data.txt
                    #echo -e "添加$userId $hls">> $logfile

                    #添加影片
                    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                    #影片id
                    movieid=$(curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" "${synctv}/api/movie/movies?page=1&max=10"|jq -r .data.movies[0].id)
                    #播放影片
                    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3  -w %{http_code} -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -d "{\"id\": \"$movieid\"}" "${synctv}/api/movie/current"
                
                    echo "$userId 已推送到Sync TV, removing from list"
                    #text="*J哥提醒你！！！！*\n\nChaturbate主播${userId}直播源已添加到SyncTV\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${hls})\n\n"
                    #text=$(echo "${text}" | sed 's/-/\\\\-/g')
                    #text=$(echo "${text}" | sed 's/_/\\\\_/g')
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
                    #text="*J哥提醒你！！！！*\n\nChaturbate主播${userId}直播源已添加到SyncTV\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${hls})\n\n"
                #text="*J哥提醒你！！！！*\n\nStripchat主播${userId}在线\n\n[让我康康！直播源地址](${m3u8site}?url=${hls})\n\n[[直播间链接](https://zh.stripchat.com/${userId})\n\n_"
                    text="*J哥提醒你！！！！*\n\nChaturbate主播${userId}在线\n\n[让我康康！直播源地址](${m3u8site}?url=${hls})\n\n[直播间链接](https://www.chaturbate.com/${userId})\n\n_"
                    text=$(echo "${text}" | sed 's/-/\\\\-/g')
                    text=$(echo "${text}" | sed 's/_/\\\\_/g')
                    curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
                    echo -e "$userId $roomid $roomToken $hls">> data.txt
                    echo -e "添加$userId $hls">> $logfile
                fi
                
                reachableIds+=("$userId")
            else 
                echo "$userId 获取直播源失败！"
                echo "错误提示：$json "
            fi
        else
            echo "$userId 可能没开播。"
        fi
        echo "-----------`date`--------------"
        sleep 2
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
#echo "开始检测失效房间"
#bash check.sh
