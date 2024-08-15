#!/bin/bash
synctv="$SYNCTV"
pdapi="$PDAPI"
logfile="log/log_`date '+%Y%m%d'`.txt"
while IFS= read -r line || [ -n "$line" ]
do
    # 从每行中提取URL
    userId=$(echo "$line" | cut -d ' ' -f1)
    roomid=$(echo "$line" | cut -d ' ' -f2)
    roomToken=$(echo "$line" | cut -d ' ' -f3)
    url=$(echo "$line" | cut -d ' ' -f4)
    # 使用curl检测URL的可用性
    # 检测URL是否包含特定字符串
    if [[ "$url" == *"https://ffdced"* ]]; then
        json_response=$(curl -s "${pdapi}/v1/member/bj?info=media&userId=${userId}" | jq .media)
        if [[ "$json_response" == "null" || -z "$json_response" ]]; then
            echo "$userId 已下播, 删除房间, 删除记录" 
            echo -e "删除$userId $hls">> $logfile
            curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\": \"${roomid}\"}" -X POST "${synctv}/api/room/admin/delete"
            sed -i "\~$url~d" data.txt
        else
            echo "$userId 直播源有效"
        fi
    elif [[ "$url" == *"https://usher.ttvnw"* ]]; then
        http_code=$(curl -o /dev/null -s -w "%{http_code}"  "https://static-cdn.jtvnw.net/previews-ttv/live_user_${userId}.jpg")
        if [ "$http_code" -ne 200 ]; then
            echo  "$userId 已下播"
            echo -e "删除$userId $hls">> $logfile
            sed -i "\~$url~d" data.txt
        else
            echo "$userId 直播源有效"
        fi
    elif curl --max-time 15 --connect-timeout 5 --retry-delay 0 --retry 1  --output /dev/null --silent --head --fail "$url"; then
        echo "$userId - $url 直播源有效"
    else
        #http_code=`curl -o /dev/null -s -w "%{http_code}"  "${synctv}/web/"`
        #if [ "$http_code" -ne 200 ]; then
            #echo -e "$userId直播源失效, 网站不能访问，不执行删除操作。"
        #else
            echo "$userId - $url 直播源失效, 删除房间, 删除记录" 
            echo -e "删除$userId $hls">> $logfile
            curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\": \"${roomid}\"}" -X POST "${synctv}/api/room/admin/delete"
            sed -i "\~$url~d" data.txt
            # 使用sed命令从文件中删除包含该URL的整行
        #fi
    fi
done < data.txt

bash paste.sh "$(cat data.txt)"
bash paste.sh "$(cat $logfile)"
