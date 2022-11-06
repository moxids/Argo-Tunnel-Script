#!/bin/bash

Verison="Beta 1.4.0"

[[ $EUID -ne 0 ]] && echo "请在root用户下运行脚本" && exit 1

menu(){
    clear
    getStatus
    echo ""
    echo "1. 一键安装CloudFlare Argo Tunnel"
    echo "2. 登录CloudFlare账户"
    echo "3. 创建一条隧道"
    echo "4. 绑定子域名到隧道"
    echo "5. 列出所有隧道"
    echo "6. 删除隧道"
    echo "7. 开启隧道"
    echo "8. 关闭隧道"
    echo "9. 更新CloudFlare Argo Tunnel"
    echo "10. 配置到systemctl中"
    echo "11. 创建config.yml配置文件"
    echo "0. 退出脚本"
    read -n2 -p "请输入选项：" menuChoose
    case ${menuChoose} in
        1) tunnelInstall ;;
        2) tunnelLogin ;;
        3) tunnelCreate ;;
        4) tunnelRoute ;;
        5) tunnelList ;;
        6) tunnelDelete ;;
        7) tunnelStart ;;
        8) tunnelStop ;;
        9) tunnelUpdate ;;
        10) serviceAdd ;;
        11) tunnelConfig ;;
        0) exit 0
    esac
}

getStatus(){
    printf "%45s\n" "【Cloudflare Argo Tunnel 一键脚本】"
    printf "%40s\n" "Web: moxid.eu.org | Telegram: @moxids"
    if [[ -n $(which cloudflared 2> /dev/null) ]]; then
        printf "%-40s %-s\n" "软件安装状态" "【已安装】"
        if [ -e "/root/.cloudflared/cert.pem" ]; then
            printf "%-40s %-s\n" "登录状态" "【已登录】"
            if [[ -n $(ps -ef | grep cloudflared | grep -v "grep") ]]; then
                printf "%-40s %-s\n" "运行状态" "【运行中】"
            else
                printf "%-40s %-s\n" "运行状态" "【未运行】"
            fi
            if [ -e "/root/.cloudflared/config.yml" ]; then
                printf "%-40s %-s\n" "配置文件" "【存在】"
            else
                printf "%-40s %-s\n" "配置文件" "【不存在】"
            fi
        else
            printf "%-40s %-s\n" "登录状态" "【未登录】"
        fi
    else
        printf "%-40s %-s\n" "软件安装状态" "【未安装】"
    fi
    
    
    #是否启动 配置文件 
}

checkInstall(){
    if [[ -z $(which cloudflared 2> /dev/null) ]]; then
        echo "【错误】检测失败或未安装CloudFlare Argo Tunnel客户端"
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    fi
}

checkLogin(){
    if [ -e "/root/.cloudflared/cert.pem" ]; then
        echo ""
    else
        echo "【错误】检测失败或未登录"
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    fi
}

checkService(){
    if [[ ! $(systemctl status cloudflared 2> /dev/null) ]]; then
        echo "【错误】检测失败或未配置到服务"
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    fi
}



# cloudflared 相关操作1xx
# systemctl 相关操作2xx
# 其他操作3xx
errorCatch(){
    case $1 in
        101) echo "【登录账户时发生错误】请将所有内容截图发送给作者 ERR101" && exit 101 ;;
        102) echo "【创建隧道时发生错误】请将所有内容截图发送给作者 ERR102" && exit 102 ;;
        103) echo "【域名绑定时发生错误】请将所有内容截图发送给作者 ERR103" && exit 103 ;;
        104) echo "【删除隧道时发生错误】请将所有内容截图发送给作者 ERR104" && exit 104 ;;
        105) echo "【查看列表时发生错误】请将所有内容截图发送给作者 ERR105" && exit 105 ;;
        106) echo "【创建服务时发生错误】请将所有内容截图发送给作者 ERR106" && exit 106 ;;
        107) echo "【更新客户端时发生错误】请将所有内容截图发送给作者 ERR107" && exit 107 ;;
        301) echo "【文件写入时发生错误】请将所有内容截图发送给作者 ERR301" && exit 301 ;;
        501) echo "【启动服务时发生错误】请将所有内容截图发送给作者 ERR501" && exit 501 ;;
        502) echo "【设置开机启动时发生错误】请将所有内容截图发送给作者 ERR502" && exit 502 ;;
        503) echo "【查看服务状态时发生错误】请将所有内容截图发送给作者 ERR503" && exit 503 ;;
        901) echo "【运行环境安装时发生错误】请将所有内容截图发送给作者 ERR901" && exit 901 ;;
        902) echo "【安装包下载时发生错误】请将所有内容截图发送给作者 ERR902" && exit 902 ;;
        903) echo "【安装时发生错误】请将所有内容截图发送给作者 ERR903" && exit 903
    esac
    echo "【未知错误】发现未在预定义错误列表中的错误代码，请讲此情况发送给作者 ERR${1}"
    exit 999
}



x86_64='x86_64'
tunnelInstall(){
    if [[ -n $(which cloudflared 2> /dev/null) ]]; then
        echo "【验证】已经安装CloudFlare Argo Tunnel客户端了，无需重复安装"
    else
        getArch=$(uname -m) #检查系统架构
        echo "【开始安装】系统架构为 ${getArch}"
        if [ -e "/usr/bin/apt-get" ]; then
            if [ ${getArch} = ${x86_64} ]; then
                arch='amd64'
            else
                arch=${getArch}
            fi
            apt-get install curl wget || errorCatch 901
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.deb || errorCatch 902
            dpkg -i cloudflared-linux-${arch}.deb || errorCatch 903
        elif [ -e "/usr/bin/dnf" ]; then
            if [ ${getArch} == ${x86_64} ]; then
                arch='amd64'
            else
                arch=${getArch}
            fi
            yum install curl wget || errorCatch 901
            wget -N https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.rpm || errorCatch 902
            rpm -i cloudflared-linux-${arch}.rpm || errorCatch 903
        elif [ -e "/usr/bin/yum" ]; then
            if [ ${getArch} == ${x86_64} ]; then
                arch='amd64'
            else
                arch=${getArch}
            fi
            yum install curl wget || errorCatch 901
            wget -N https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.rpm || errorCatch 902
            rpm -i cloudflared-linux-${arch}.rpm || errorCatch 903
        else
            echo "【错误】未发现适用于该系统的安装方式，请联系作者" && exit 999
        fi
    fi
    echo '==========%登录%=========='
    if [ -e "/root/.cloudflared/cert.pem" ]; then
        echo "【已登录】如需重新登录请执行该命令删除相关文件"
        echo "rm -rf ~/.cloudflared/cert.pem"
    else
        echo "打开链接，登录到Cloudflare，确保账户下有一个或多个域名"
        cloudflared tunnel login || errorCatch 101
        if [ -e "/root/.cloudflared/cert.pem" ]; then
            echo "【登陆成功】"
        else
            echo "【登陆二验失败】请将相关信息发送给作者"
            exit 1
        fi
        echo '==========%结束%=========='
    fi
    echo '==========%创建%=========='
        read -p ">_输入隧道名称：" tunnelName
        cloudflared tunnel create ${tunnelName} || errorCatch 102
    echo '==========%结束%=========='
    clear
    echo '==========%绑定%=========='
    read -p ">_完整输入想要绑定的域名：" tunnelDomain
    cloudflared tunnel route dns ${tunnelName} ${tunnelDomain} || errorCatch 103
    echo '==========%结束%=========='
    clear
    echo '==========%列表%=========='
    cloudflared tunnel list || errorCatch 105
    echo '==========%结束%=========='
    echo '==========%配置%=========='
    if [ -e "/root/.cloudflared/config.yml" ]; then
        echo '【警告】这将替换掉原本的配置文件，目前脚本不支持多域名和分流'
    fi
    read -p ">_查看上方列表，输入隧道ID：" tunnelID
    read -p ">_输入协议名称（http;https;unix;tcp;ssh;rdp;bastion）：" tunnelService
    read -p ">_输入想要Tunnel代理的端口：" tunnelPort
    echo "正在写入文件中，请稍后。。。"
    echo "tunnel: ${tunnelID}" > ~/.cloudflared/config.yml || errorCatch 301
    echo "credentials-file: /root/.cloudflared/${tunnelID}.json" >> ~/.cloudflared/config.yml
    echo "ingress:" >> ~/.cloudflared/config.yml
    echo "  - hostname: ${tunnelDomain}" >> ~/.cloudflared/config.yml
    echo "    service: $tunnelService://localhost:${tunnelPort}" >> ~/.cloudflared/config.yml
    echo "  - service: http_status:404" >> ~/.cloudflared/config.yml
    echo '==========%结束%=========='
    clear
    echo '==========%服务%=========='
    echo "添加cloudflared到service中（脚本运行需要）"
    cloudflared service install || errorCatch 106
    systemctl start cloudflared || errorCatch 501
    systemctl enable cloudflared || errorCatch 502
    if [[ ! $(systemctl status cloudflared 2> /dev/null) ]]; then
        echo "【配置失败】请手动运行下面的代码，并将错误信息发送给作者"
        echo "cloudflared service install"
        echo "systemctl start cloudflared"
        echo "systemctl enable cloudflared"
        exit 1
    fi
    echo '==========%结束%=========='
    clear
    echo '==========%启动%=========='
    systemctl start cloudflared || errorCatch 501
    #systemctl status cloudflared || errorCatch 602
    if [[ -n $(ps -ef | grep cloudflared | grep -v "grep") ]]; then
        echo "【启动成功】"
    else
        echo "【启动失败】请手动运行下面的代码，并将错误信息发送给作者"
        echo "systemctl start cloudflared"
        echo "systemctl status cloudflared -l"
    fi
    echo '==========%结束%=========='
}

tunnelLogin(){
    checkInstall
    echo '==========%登录%=========='
    if [ -e "/root/.cloudflared/cert.pem" ]; then
        echo "【已登录】如需重新登录请手动执行以下代码删除文件"
        echo "rm ~/.cloudflared/cert.pem"
        echo '==========%结束%=========='
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    else
        echo "打开链接，登录到Cloudflare，确保账户下有一个或多个域名"
        cloudflared tunnel login || errorCatch 101
        checkLogin
        echo '==========%结束%=========='
        read -s -n1 -p "【成功】按任意键回到菜单。。。" && menu
    fi
}

tunnelCreate(){
    checkInstall
    checkLogin
    echo '==========%创建%=========='
    read -p ">_输入隧道名称：" tunnelName
    cloudflared tunnel create ${tunnelName} || errorCatch 102
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelRoute(){
    checkInstall
    checkLogin
    tunnelList
    echo '==========%绑定%=========='
    read -p ">_输入隧道名称：" tunnelName
    read -p ">_完整输入想要绑定的域名：" tunnelDomain
    cloudflared tunnel route dns ${tunnelName} ${tunnelDomain} || errorCatch 103
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelConfig(){
    checkInstall
    checkLogin
    echo '==========%配置%=========='
    if [ -e "/root/.cloudflared/config.yml" ]; then
        echo '【警告】这将替换掉原本的配置文件，目前脚本不支持多域名和分流'
    fi
    read -p ">_输入隧道名称：" tunnelName
    read -p ">_完整输入隧道域名：" tunnelDomain
    read -p ">_输入隧道ID：" tunnelID
    read -p ">_输入协议名称（http;https;unix;tcp;ssh;rdp;bastion）：" tunnelService
    read -p ">_输入想要Tunnel代理的端口：" tunnelPort
    echo "正在写入文件中，请稍后。。。"
    echo "tunnel: ${tunnelID}" > ~/.cloudflared/config.yml || errorCatch 301
    echo "credentials-file: /root/.cloudflared/${tunnelID}.json" >> ~/.cloudflared/config.yml
    echo "ingress:" >> ~/.cloudflared/config.yml
    echo "  - hostname: ${tunnelDomain}" >> ~/.cloudflared/config.yml
    echo "    service: $tunnelService://localhost:${tunnelPort}" >> ~/.cloudflared/config.yml
    echo "  - service: http_status:404" >> ~/.cloudflared/config.yml
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

serviceAdd(){
    checkInstall
    checkLogin
    echo '==========%服务%=========='
    echo "添加cloudflared到service中（脚本运行所需）"
    cloudflared service install || errorCatch 106
    systemctl start cloudflared || errorCatch 501
    systemctl enable cloudflared || errorCatch 502
    checkService
    echo '==========%结束%=========='
    read -s -n1 -p "【成功】按任意键回到菜单。。。" && menu
}

tunnelStart(){
    checkInstall
    checkLogin
    checkService
    echo '==========%启动%=========='
    systemctl start cloudflared || errorCatch 501
    systemctl status cloudflared || errorCatch 503
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelStop(){
    checkInstall
    checkLogin
    echo '==========%停止%=========='
    systemctl stop cloudflared || errorCatch 504
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelList(){
    checkInstall
    checkLogin
    echo '==========%列表%=========='
    cloudflared tunnel list || errorCatch 105
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelDelete(){
    checkInstall
    checkLogin
    tunnelList
    echo '==========%删除%=========='
    read -p "输入隧道名称：" tunnelName
    cloudflared tunnel delete -f ${tunnelName} || errorCatch 104
    echo '==========%结束%=========='
    read -s -n1 -p "【完成】按任意键回到菜单。。。" && menu
}

tunnelUpdate(){
    checkInstall
    echo '==========%更新%=========='
    echo '【当前版本】'
    cloudflared version
    echo '【更新方式】'
    echo '1. 默认更新方法（失败概率较大，但为程序内置）'
    echo '2. 【BETA】重新安装包（仅在方法1失效时且必须更新时尝试，将会停止所有隧道运行）'
    echo ''
    echo '方法1,2皆有失败几率，推荐使用这篇文章的安装方法，只需要执行包管理器的更新命令即可'
    echo 'https://moxid.eu.org/archives/3/'
    echo ''
    read -n1 -p "请输入选项：" updateChoose
    case ${updateChoose} in
        1) cloudflared update && echo '==========%结束%==========' && read -s -n1 -p "按任意键回到菜单。。。" && menu || errorCatch 107 ;;
        2) forceUpdate || errorCatch 107
    esac
    read -s -n1 -p "按任意键回到菜单。。。" && menu
}

forceUpdate(){
    cloudflared tunnel stop 2> /dev/null
    systemctl stop cloudflared 2> /dev/null
    getArch=$(uname -m) #检查系统架构
    echo "【开始更新】系统架构为 ${getArch}"
    if [ -e "/usr/bin/apt-get" ]; then
        if [ ${getArch} = ${x86_64} ]; then
            arch='amd64'
        else
            arch=${getArch}
        fi
        apt-get install curl wget || errorCatch 901
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.deb || errorCatch 902
        dpkg -i cloudflared-linux-${arch}.deb || errorCatch 903
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    elif [ -e "/usr/bin/dnf" ]; then
        if [ ${getArch} == ${x86_64} ]; then
            arch='amd64'
        else
            arch=${getArch}
        fi
        yum install curl wget || errorCatch 901
        wget -N https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.rpm || errorCatch 902
        rpm -i cloudflared-linux-${arch}.rpm || errorCatch 903
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    elif [ -e "/usr/bin/yum" ]; then
        if [ ${getArch} == ${x86_64} ]; then
            arch='amd64'
        else
            arch=${getArch}
        fi
        yum install curl wget || errorCatch 901
        wget -N https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}.rpm || errorCatch 902
        rpm -i cloudflared-linux-${arch}.rpm || errorCatch 903
        read -s -n1 -p "按任意键回到菜单。。。" && menu
    else
        echo "【错误】未发现适用于该系统的安装方式，请联系作者" && exit 999
    fi
}


menu
