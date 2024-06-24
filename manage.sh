#!/bin/bash
# Config

cookie="$COOKIE"
userToken="$USERTOKEN"
bot="$BOTTOKEN"
synctv="$SYNCTV"
username="$USERNAME"
password="$PASSWORD"
m3u8site="$M3U8SITE"

userToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' --data-raw "{\"username\": \"${username}\",\"password\": \"${password}\"}" -X POST "${synctv}/api/user/login"|jq -r .data.token`
echo $userToken
roomids=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}" "${synctv}/api/admin/room/list?page=1&max=50&sort=createdAt&order=asc&search=all&keyword=&status="|jq -r .data.list[].roomId`
echo $roomids

function push() {
    echo 123
}

function delallroom(){

  for roomid in ${roomids}; do
    #curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}"  --data-raw "{\"id\": \"${roomid}\"}" -X POST "${synctv}/api/admin/room/approve"
    roomToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}"  --data-raw "{\"roomid\": \"${roomid}\",\"password\":\"\"}" -X POST "${synctv}/api/room/login"|jq -r .data.token`
    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\":\"${roomid}\"}" -X POST "${synctv}/api/room/admin/delete"
  done
}

function play(){
  for roomid in ${roomids}; do
    roomToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}"  --data-raw "{\"roomid\": \"${roomid}\",\"password\":\"\"}" -X POST "${synctv}/api/room/login"|jq -r .data.token`
    movieinfo=$(curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" "${synctv}/api/movie/movies?page=1&max=10")
    movieid=$(echo $movieinfo|jq -r .data.movies[0].id)
    moviename=$(echo $movieinfo|jq -r .data.movies[0].base.name)
    echo "$moviename"
    curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" -d "{\"id\": \"$movieid\"}" "${synctv}/api/movie/current"
done
}

function delroom(){
  for roomid in ${roomids}; do
    roomToken=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${userToken}"  --data-raw "{\"roomid\": \"${roomid}\",\"password\":\"\"}" -X POST "${synctv}/api/room/login"|jq -r .data.token`
    movieinfo=$(curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}" "${synctv}/api/movie/movies?page=1&max=10")
    movieid=$(echo $movieinfo|jq -r .data.movies[0].id)
    moviename=$(echo $movieinfo|jq -r .data.movies[0].base.name)
    url=$(echo $movieinfo|jq -r .data.movies[0].base.url)   
    if curl --max-time 15 --connect-timeout 5 --retry-delay 0 --retry 1 --output /dev/null --silent --head --fail "$url"; then
        echo -e "$moviename直播源有效 - $url"
    else
        echo -e "$moviename直播源失效, 删除房间, 删除记录  - $url"
        curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 -w "%{http_code}" -H 'accept:application/json, text/plain, */*' -H "authorization:${roomToken}"  --data-raw "{\"roomid\": \"${roomid}\"}" -X POST "${synctv}/api/room/admin/delete"
            sed -i "\~$url~d" data.txt
            # 使用sed命令从文件中删除包含该URL的整行
    fi
  done
}

#play
#delete
$1
