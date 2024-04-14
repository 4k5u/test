#!/bin/bash
synctv="$SYNCTV"
logfile="log/log_`date '+%Y%m%d'`.txt"
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
        http_code=`curl -o /dev/null -s -w "%{http_code}"  "${synctv}/web/"`
        if [ "$http_code1" -ne 200 ]; then
            echo -e "$userId直播源失效, 网站不能访问，不执行删除操作。"
        else
            echo "$userId - $url 直播源失效, 删除房间, 删除记录" 
            echo -e "删除$userId $hls">> $logfile
            curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\": \"${roomid}\"}" -X POST "${synctv}/api/room/delete"
            sed -i "\~$url~d" data.txt
            # 使用sed命令从文件中删除包含该URL的整行
        fi
    fi
done < data.txt

bash paste.sh "$(cat data.txt)"
bash paste.sh "$(cat $logfile)"
