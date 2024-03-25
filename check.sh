#!/bin/bash

userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
echo -e "bot:$BOTTOKEN"
echo -e "user:Token$USERTOKEN"
echo -e "synctv:$SYNCTV"

while IFS= read -r line || [ -n "$line" ]
do
    # 从每行中提取URL
    userId=$(echo "$line" | cut -d ' ' -f1)
    roomid=$(echo "$line" | cut -d ' ' -f2)
    roomToken=$(echo "$line" | cut -d ' ' -f3)
    url=$(echo "$line" | cut -d ' ' -f4)
    # 使用curl检测URL的可用性
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "$userId - $url 直播源有效"
    else
        req=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "|%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\": \"${roomid}\"}" -X POST "${synctv}/api/room/delete"`
        result=$(echo "$req" | cut -d '|' -f1)
        http_code=$(echo "$req" | cut -d '|' -f2)
        if [ "$http_code" -ne 204 ]; then
            echo -e "$userId直播源失效, 删除房间失败，请求${result}"
        else
            echo "$userId - $url 直播源失效, 删除房间, 删除记录" 
            sed -i "\~$url~d" sync.txt
            # 使用sed命令从文件中删除包含该URL的整行
        fi
    fi
done < data.txt
