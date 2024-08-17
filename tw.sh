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
userIds="kyul365 ddooyaa sooflower golaniyule0 bps1016";
#
#afreeca gusdk2362  sol3712 m0m099  namuh0926  m0m099
#pop162cm
#flex golaniyule0
#? lovether

echo -e `date` >> $logfile

echo "-------------------twitch------------------------------"
for userId in ${userIds}; do
    stream=$(curl  -s "https://gql.twitch.tv/gql" -H "Client-ID:kimne78kx3ncx6brgo4mv6wki5h1ko" --data-raw '{"operationName":"UseLive","variables":{"channelLogin":"'${userId}'"},"extensions":{"persistedQuery":{"version":1,"sha256Hash":"639d5f11bfb8bf3053b424d9ef650d04c4ebb7d94711d644afb08fe9a0fad5d9"}}}'|jq .data.user.stream)
    if [ -n "$stream" ] && [ "$stream" != null ] ; then
        echo "${userId}在线，开始获取直播源"
        if grep -q "${userId}" data.txt; then
            echo "The UID $userId exists in data.txt"
        else
            res=$(curl  -s "https://gql.twitch.tv/gql" -H "Client-ID:kimne78kx3ncx6brgo4mv6wki5h1ko" --data-raw '{"operationName":"PlaybackAccessToken","extensions":{"persistedQuery":{"version":1,"sha256Hash":"0828119ded1c13477966434e15800ff57ddacf13ba1911c129dc2200705b0712"}},"variables":{"isLive":true,"login":"'${userId}'","isVod":false,"vodID":"","playerType":"embed"}}')
            startTime=$(echo "$stream"|jq -r .createdAt)
            streamPlaybackAccessToken=$(echo "$res"| jq -r .data.streamPlaybackAccessToken.value)
            signature=$(echo "$res"| jq -r .data.streamPlaybackAccessToken.signature)
            timestamp=$(date +%s)
            img="https://static-cdn.jtvnw.net/previews-ttv/live_user_${userId}.jpg?${timestamp}"
        
            murl="https://usher.ttvnw.net/api/channel/hls/${userId}.m3u8"
            encoded_token=$(printf "%s" "$streamPlaybackAccessToken" | jq -sRr @uri)
            url="${murl}?client_id=kimne78kx3ncx6brgo4mv6wki5h1ko&token=${encoded_token}&sig=${signature}&allow_source=true&allow_audio_only=true"
            #echo "$encoded_url"
        
            if [ -n "$url" ] && [ "$url" != null ] ; then
                hls=$url
                echo "${userId}获取成功。"
                echo "直播源：${hls}"

                echo "$userId 推送到TG"
                text="<b>@kbjba 提醒你！！！！</b>\n\nTwitch 主播 ${userId} 在线\n\n本场开播时间：$startTime（UTC时间慢8小时）\n\n<a href='$hls'>直播源地址</a>\n\n<a href='twitch.tv/${userId}'>直播间链接</a>\n\n-----"
                #text=$(echo "${text}" | sed 's/-/\\\\-/g')
                curl -H 'Content-Type: application/json' -d "{\"chat_id\": \"@Sexbjlive_Chat\", \"caption\":\"$text\", \"photo\":\"$img\"}" "https://api.telegram.org/${bot}/sendPhoto?parse_mode=HTML"
                echo -e "$userId aaa bbb $hls">> data.txt
                
                echo -e "添加$userId $hls">> $logfile
            else 
                echo "$userId 获取直播源失败！"
                echo "错误提示：$res"  #$json "
            fi
        fi
    else
        echo "$userId 可能没开播。"
    fi
    echo "-----------`date`--------------"
    sleep 2
done
        
