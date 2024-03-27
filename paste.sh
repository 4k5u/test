if [[ -z "$(command -v curl)" ]];then
    echo "没有curl，请安装"
exit 1
fi
content=$*
if [[ "$content" ]];then
    share_link="https://paste.ubuntu.com"$(curl -v --data-urlencode "content=${content}" -d "poster=4k6" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | grep "Location" | awk '{print $3}')
    # mac下
    echo -e "\n 分享链接：\x1B[31m${share_link}\x1B[0m"
    # linux下
    echo -e "\n 分享链接：\e[31m${share_link}\e[0m"
else
    echo "没有传入要上传的文本"
    echo -e "一般是这样：\x1B[31mbash $0 \x1B[32m\"你要上传的文本\"\x1B[0m"
fi
