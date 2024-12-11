#!/bin/bash
# Config
#用法：bash synctv.sh moem9e9 
echo "---------pandalive----------"

cookie="$COOKIE"
userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
username="$USERNAME"
password="$PASSWORD"
m3u8site="$M3U8SITE"
pdapi="$PDAPI"
logfile="log/log_`date '+%Y%m%d'`.txt"
#userIds=$1


fetch_json() {
    local offset="$1"
    local limit="$2"
    local json
    json=$(curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" \
        -H "cookie:${cookie}" \
        -X POST  "${pdapi}/v1/live?offset=${offset}&limit=${limit}&orderBy=hot&onlyNewBj=N")
    echo "$json"
}
# 主要脚本
json_file1="json1.tmp"
json_file2="json2.tmp"
merged_json_file="merged.json"

# 获取第一页的 JSON 数据并写入临时文件1
fetch_json 0 96 > "$json_file1"
if [ "$(jq -r .result < "$json_file1")" != true ]; then
    echo "获取列表失败"
    cat "$json_file1"
    exit 1
fi
echo "------$(date)------"
total=$(jq -r .page.total < "$json_file1")
echo -n "在线主播:$total | 获取前96主播"
# 如果在线主播数超过96，则获取额外的页面并合并JSON数据
if [ "$total" -gt 96 ]; then
    remaining=$((total - 96))
    page=2
    while [ "$remaining" -gt 0 ]; do
        echo -n " | 获取第$page页"
        offset=$(( (page - 1) * 96 ))
        fetch_json "$offset" 96 > "$json_file2"
        #echo  "使用jq合并两个JSON文件中的list数组，并去除重复项"
        jq -s '.[0].list += .[1].list | unique_by(.code)' "$json_file1" "$json_file2" > "$merged_json_file"
        sed -i 's/^\[//; s/\]$//' "$merged_json_file"
        #jq '.list' "$merged_json_file"|head -n 10
        #echo "更新json_file1以便下次追加数据"
        mv  "$merged_json_file" "$json_file1"
        remaining=$((remaining - 96))
        page=$((page + 1))
    done
fi

#echo "最终合并后的JSON数据保存在 json 中"
mv  "$json_file1"  all.json

#echo "清理临时文件"
rm "$json_file2"
json=$(cat all.json)

isAdults=$(echo "$json" |jq .list[]|jq 'select(.isAdult == true)'|jq .userId|wc -l)
fans=$(echo "$json" |jq .list[]|jq 'select(.type == "fan")'|jq .userId|wc -l)
isPws=$(echo "$json" |jq .list[]|jq 'select(.isPw == true)'|jq .userId|wc -l)
echo " | 19+房间:$isAdults | 粉丝房:$fans | 密码房:$isPws"

#cat json |jq .list[]|jq 'select(.type == "free")'|jq .userId
#userIds=$(echo $json|jq -r .list[].userId)
IFS=$'\n' read -r -d '' -a onlineIds < <(jq -r '.list[].userId' <<< "$json")
echo "${onlineIds[@]}" > userid.txt
echo "获取到主播数：${#onlineIds[@]}"

freeIds=($(echo "$json"|jq .list[]|jq 'select(.type == "free")'|jq -r .userId))
watchIds="jinricrew1 guqehdwhgkq sssna777 qwer00725 flowerwar nobleinc 1stforever green10004 akakak11112 rico0210 jodong2 in0410 dks2003 melona0 maby33 imsocutesexy eerttyui12 soraa3 bmg4262 nyangnyang1004 minllor5 won110 naras2 dana9282 tyy750ii lovable12 leeaeae123 mozzzi yourare pyey3380 jubin0725 362540 hotse777 redholic377 thgml1212 yasexy na2ppueum youha1004 foru5858 dkssudgktpdy233 anystar00 jjine0127 howru010 stuiliillive emforhs1919 lovesong2 20152022 jenny9999 choyunkyung jinricp pandaex happyy2 4ocari na2ppeum onlyone521 imissy0u moem9e9 likecho cool3333 100472 lovemeimscared starsh2802 imgroot5 okzzzz eli05021212 ohhanna dmsdms1247 54soda ajswl12 qwas33 getme1004 sseerrii0201 o111na homegirl cho77j chuing77 ksb0219 tess00 bom124 sonming52 banet523 giyoming axcvdbs23 apffhdn1219 3ww1ww3 bongbong486 duk97031 deer9805 romantic09 dkdlfjqm758 muse62 chuchu22 siyun0813 nemu00 Vvvv1212 xxaaop syxx12 day59day obzee7 dudvv7 ahri0801 soso621 missedyou imanatural Sharon9sea seozzidooboo saone451 acac88 hyuna0721 2dayday pupu28 ee5844 rmrm1313 zzeongi2 ehdbs0105 ksb0219";

# 使用grep命令获取group1和group2中的重复元素，并组成一个新的数组
#userIds=($(echo "$watchIds ${freeIds[@]}" | tr ' ' '\n' | sort | uniq -d))
# 提取在线关注用户数组
userIds=()
for id in $watchIds; do
    for freeId in "${freeIds[@]}"; do
        if [[ "$id" == "$freeId" ]]; then
            userIds+=("$id")
            break
        fi
    done
done

# 输出元素
echo "监控中在线主播：${userIds[@]}"
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
    for userId in ${userIds[@]}; do
        if grep -q "${userId}" data.txt; then
            echo "The UID $userId exists in data.txt"
        else
            json=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" -H 'x-device-info:{"t":"webMobile","v":"1.0","ui":24631221}' -H "cookie:${cookie}" -X POST  "${pdapi}/v1/live/play?action=watch&userId=${userId}"` 
            hls=`echo $json| jq -r .PlayList.hls[0].url`
            img=`echo $json| jq -r .media.ivsThumbnail`
            startTime=`echo "$json"| jq -r .media.startTime`
            echo "开始获取直播源"
            if [ -n "$hls"  ] &&  [ "$hls" != null ]; then
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

                    #添加影片
                    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -w %{http_code} --data-raw "${jsondata}" -X POST "${synctv}/api/movie/push"
                    #影片id
                    movieid=$(curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" "${synctv}/api/movie/movies?page=1&max=10"|jq -r .data.movies[0].id)
                    #播放影片
                    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3  -w %{http_code} -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -d "{\"id\": \"$movieid\"}" "${synctv}/api/movie/current"
                
                    echo "$userId 已推送到Sync TV, removing from list"
                    #text="*J哥提醒你！！！！*\n\nPanda主播${userId}直播源已添加到SyncTV\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直达地址，sync维护！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${userId})\n\n"
                    #text=$(echo "${text}" | sed 's/-/\\\\-/g')
                    #curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
                elif [ "$roomid" = null ]; then
                    echo $room|jq -r .error
                    echo "创建房间失败，可能已有同名房间，跳过此ID" 
                else 
                    echo "创建房间失败，跳过此ID（错误提示${room}）" 
                fi
            
                echo "$userId 推送到TG"
                #text="*J哥提醒你！！！！*\n\nPanda主播${userId}直播源已添加到SyncTV\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直达地址，让我康康！](${synctv}/web/cinema/${roomid})\n\n[直达地址②，再次康康！](${m3u8site}?url=${userId})\n\n"
                text="*J哥提醒你！！！！*\n\nPanda主播${userId}上线\n\n本场开播时间：$startTime（韩国时间快1小时）\n\n[直播源观看](${m3u8site}?url=${userId})\n\n[需要安装插件才能播](https://t.me/kbjba1/98804)\n\n[直播间地址](https://www.pandalive.co.kr/live/play/${userId})\n\n"
                text=$(echo "${text}" | sed 's/-/\\\\-/g')
                curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=MarkdownV2"
                echo -e "$userId $roomid $roomToken $hls">> data.txt
                echo -e "添加$userId $hls">> $logfile
                reachableIds+=("$userId")
            else 
                echo "$userId 获取直播源失败！"
                echo "错误提示：$json "
            fi
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

