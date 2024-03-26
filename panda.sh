#!/bin/bash
# Config
#用法：bash synctv.sh moem9e9 

cookie="$COOKIE"
userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
username="$USERNAME"
password="$PASSWORD"
logfile="log/log_`date '+%Y%m%d'`.txt"
#userIds=$1
userIds="jinricp pandaex happyy2 4ocari na2ppeum onlyone521 imissy0u moem9e9 cool3333 lovemeimscared starsh2802 imgroot5 okzzzz eli05021212 ohhanna dmsdms1247 54soda ajswl12 qwas33 getme1004 sseerrii0201 banet523 o111na homegirl cho77j chuing77 100472 ksb0219 tess00 bom124 sonming52 banet523 giyoming axcvdbs23 apffhdn1219 3ww1ww3 bongbong486 duk97031 deer9805 romantic09 dkdlfjqm758 muse62 chuchu22 siyun0813 nemu00 Vvvv1212 xxaaop syxx12 day59day likecho obzee7 dudvv7 ahri0801 soso621 missedyou imanatural";
#gusdk2362 162cm sol3712 m0m099 lovether namuh0926

echo -e `date` >> $logfile
userToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' --data-raw "{\"username\": \"${username}\",\"password\": \"${password}\"}" -X POST "${synctv}/api/user/login"|jq -r .data.token`
echo $userToken

unreachableIds=()
#for ((i=1; i<=1000; i++)); do
#    echo "Round $i:"
    for userId in ${userIds}; do
        json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" -H 'x-device-info:{"t":"webMobile","v":"1.0","ui":24631221}' -H "cookie:${cookie}" -X POST  "https://api.pandalive.co.kr/v1/live/play?action=watch&userId=${userId}"` 
        hls=`echo $json| jq -r .PlayList.hls[0].url`
        img=`echo $json| jq -r .media.thumbUrl`
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
                echo -e "添加$userId $hls">> $logfile
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} -X POST "${synctv}/api/movie/clear"
                curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                echo "$userId 已推送到Sync TV, removing from list"
                text="*J哥提醒你！！！！*\n\n${userId}直播源已添加到SyncTV\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n"
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

