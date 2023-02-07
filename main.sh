#!/bin/sh

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

# The URL of the script project is:
# https://github.com/XTLS/Xray-install

FILES_PATH=${FILES_PATH:-./}

# Gobal verbals

# Xray current version
CURRENT_VERSION=''

# Xray latest release version
RELEASE_LATEST=''

get_current_version() {
    # Get the CURRENT_VERSION
    if [[ -f "${FILES_PATH}/web" ]]; then
        CURRENT_VERSION="$(${FILES_PATH}/web -version | awk 'NR==1 {print $2}')"
        CURRENT_VERSION="v${CURRENT_VERSION#v}"
    else
        CURRENT_VERSION=""
    fi
}

get_latest_version() {
    # Get Xray latest release version number
    local tmp_file
    tmp_file="$(mktemp)"
    if ! curl -sS -H "Accept: application/vnd.github.v3+json" -o "$tmp_file" 'https://api.github.com/repos/XTLS/Xray-core/releases/latest'; then
        "rm" "$tmp_file"
        echo 'error: Failed to get release list, please check your network.'
        exit 1
    fi
    RELEASE_LATEST="$(jq .tag_name "$tmp_file" | sed 's/\"//g')"
    if [[ -z "$RELEASE_LATEST" ]]; then
        if grep -q "API rate limit exceeded" "$tmp_file"; then
            echo "error: github API rate limit exceeded"
        else
            echo "error: Failed to get the latest release version."
        fi
        "rm" "$tmp_file"
        exit 1
    fi
    "rm" "$tmp_file"
}

download_xray() {
    DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/download/$RELEASE_LATEST/Xray-linux-64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
    if ! wget -qO "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    if [[ "$(cat "$ZIP_FILE".dgst)" == 'Not Found' ]]; then
        echo 'error: This version does not support verification. Please replace with another version.'
        return 1
    fi

    # Verification of Xray archive
    for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
        SUM="$(${LISTSUM}sum "$ZIP_FILE" | sed 's/ .*//')"
        CHECKSUM="$(grep ${LISTSUM^^} "$ZIP_FILE".dgst | grep "$SUM" -o -a | uniq)"
        if [[ "$SUM" != "$CHECKSUM" ]]; then
            echo 'error: Check failed! Please check your network or try again.'
            return 1
        fi
    done
}

decompression() {
    busybox unzip -q "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        "rm" -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_xray() {
    install -m 755 ${TMP_DIRECTORY}/xray ${FILES_PATH}/web
}

run_xray() {
    re_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)   
    if [ "${re_uuid}" = "" ]; then
        new_uuid="$(cat /proc/sys/kernel/random/uuid)"
        curl -sXPOST $REPLIT_DB_URL/re_uuid="${new_uuid}" 
    fi

    if [ "${uuid}" = "" ]; then
        user_uuid=$(curl -s $REPLIT_DB_URL/re_uuid)
    else
        user_uuid=${uuid}
    fi

    cp -f ./config.json /tmp/config.json
    sed -i "s|uuid|${user_uuid}|g" /tmp/config.json
    ./web -c /tmp/config.json 2>&1 >/dev/null &
    replit_xray_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"replit_xray_vmess\",\
\"add\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"port\": \"443\",\
\"id\": \"${user_uuid}\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${REPL_SLUG}.${REPL_OWNER}.repl.co\",\
\"path\": \"/${user_uuid}-vm\",\
\"tls\": \"tls\"\
}"\
    | base64 -w 0)"
    replit_xray_vless="vless://${user_uuid}@${REPL_SLUG}.${REPL_OWNER}.repl.co:443?encryption=none&security=tls&type=ws&host=${REPL_SLUG}.${REPL_OWNER}.repl.co&path=%2F${user_uuid}-vl#replit_xray_vless"
    replit_xray_trojan="trojan://${user_uuid}@${REPL_SLUG}.${REPL_OWNER}.repl.co:443?security=tls&type=ws&host=${REPL_SLUG}.${REPL_OWNER}.repl.co&path=%2F${user_uuid}-tr#replit_xray_trojan"
    echo ""
    yellow "VMess + ws + TLS 通用分享链接如下："
    echo ${replit_xray_vmess}
    echo ""
    yellow "分享二维码如下："
    qrencode -t ansiutf8 ${replit_xray_vmess}
    echo ""
    yellow "VLESS + ws + TLS 通用分享链接如下："
    echo ${replit_xray_vless}
    echo ""
    yellow "分享二维码如下："
    qrencode -t ansiutf8 ${replit_xray_vless}
    echo ""
    yellow "Trojan + ws + TLS 通用分享链接如下："
    echo ${replit_xray_trojan}
    echo ""
    yellow "分享二维码如下："
    qrencode -t ansiutf8 ${replit_xray_trojan}
    echo ""
    yellow "shadowsocks + ws + tls 配置明文如下："
  green "服务器地址：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    green "端口：443"
    green "密码：${user_uuid}"
    green "加密方式：chacha20-ietf-poly1305"
    green "传输协议：ws"
    green "host：${REPL_SLUG}.${REPL_OWNER}.repl.co"
    green "path路径：/${user_uuid}-ss"
    green "tls：开启"
    echo ""
    yellow "更多项目，请关注：小御坂的破站"
    echo ""
    while true; do
      curl "https://${REPL_SLUG}.${REPL_OWNER}.repl.co"
      sleep 60
    done
}

# Two very important variables
TMP_DIRECTORY="$(mktemp -d)"
ZIP_FILE="${TMP_DIRECTORY}/web.zip"

get_current_version
get_latest_version
if [ "${RELEASE_LATEST}" = "${CURRENT_VERSION}" ]; then
    "rm" -rf "$TMP_DIRECTORY"
    run_xray
fi
download_xray
EXIT_CODE=$?
if [ ${EXIT_CODE} -eq 0 ]; then
    :
else
    "rm" -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    run_xray
fi
decompression "$ZIP_FILE"
install_xray
"rm" -rf "$TMP_DIRECTORY"

run_xray
