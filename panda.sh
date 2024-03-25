#!/bin/bash
# Config
#用法：bash synctv.sh moem9e9 

cookie="$COOKIE"
userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
#userIds=$1
userIds="jinricp pandaex happyy2 4ocari na2ppeum onlyone521 imissy0u moem9e9 cool3333 lovemeimscared starsh2802 imgroot5 okzzzz eli05021212 ohhanna dmsdms1247 54soda ajswl12 qwas33 getme1004 sseerrii0201 banet523 o111na homegirl cho77j chuing77 100472 ksb0219 tess00 bom124 sonming52 namuh0926 banet523 giyoming axcvdbs23 apffhdn1219 sol3712 3ww1ww3 bongbong486 duk97031 deer9805 romantic09 dkdlfjqm758 162cm muse62 chuchu22 m0m099 lovether siyun0813 nemu00 Vvvv1212 gusdk2362 xxaaop";

unreachableIds=()
#for ((i=1; i<=1000; i++)); do
#    echo "Round $i:"
    for userId in ${userIds}; do
        json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" -H 'x-device-info:{"t":"webMobile","v":"1.0","ui":24631221}' -H "cookie:${cookie}" -X POST  "https://api.pandalive.co.kr/v1/live/play?action=watch&userId=${userId}"` 
        hls=`echo $json| jq -r .PlayList.hls[0].url`
        echo "开始获取直播源"
        if [ -n "$hls"  ] &&  [ "$hls" != null ]; then
            echo "${userId}获取成功。"
            echo "直播源：${hls}"
            echo "开始创建房间" 
            room=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}" --data-raw "{\"roomName\":\"${userId}\",\"password\":\"\",\"setting\": {\"hidden\": false}}" -X POST "${synctv}/api/room/create"`
            roomid=`echo $room|jq -r .data.roomId`
            roomToken=`echo $room|jq -r .data.token`
            echo "房间id：$roomid"
            if [ -n "$roomid"  ] && [ "$roomid" != null ]; then
                jsondata="{\"name\": \"${userId}\",\"url\": \"${hls}\",\"type\": \"m3u8\",\"live\": true}"
                echo -e "$userId $roomid $roomToken $hls">> data.txt
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} -X POST "${synctv}/api/movie/clear"
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                echo "$userId 已推送到Sync TV, removing from list"
                text="*提醒！！！！*\n\n${userId}已添加到SyncTV\n\n[直达地址](${synctv}/web/cinema/${roomid})\n\n"
                curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"text\":\"$text\"}" "https://api.telegram.org/${bot}/sendMessage?parse_mode=MarkdownV2"
            elif [ "$roomid" = null ]; then
                echo $room|jq -r .error
                echo "创建房间失败，可能已有同名房间，跳过此ID" 
            else 
                echo "创建房间失败，跳过此ID（错误提示${room}）" 
            fi
            reachableIds+=("$userId")
        else 
            echo "$userId 获取直播源失败！"
            echo "错误提示：$json "
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
