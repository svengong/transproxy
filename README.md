## 说明

这个项目旨在可以快速将一台linux设备，初始化为透明代理网关。本代码在ubuntu22.04虚拟机上测试通过。


## 使用 

### 安装依赖

    依赖一定要先安装

```
    sudo apt install ipset 
    pip3 install pyyaml requests argparse
```

### 下载本项目

```
git clone git@github.com:svengong/transproxy.git && chmod +x *
```

### 下载clash

    使用下面的chatgpt帮忙写的脚本下载，或者手动下载后赋予执行权限
```
    #!/bin/bash

    # Get the latest release tag
    latest_release=$(curl -s https://api.github.com/repos/Dreamacro/clash/releases/latest | grep "tag_name" | awk '{print $2}' | tr -d '",')

    # Download the amd64 version of the release file
    filename="clash-linux-amd64-${latest_release}.gz"
    curl -L "https://github.com/Dreamacro/clash/releases/download/${latest_release}/$filename" -o "$filename"

    # Unzip the downloaded file
    gunzip "$filename"

    # Give execute permission to the binary file
    binary_file="clash-linux-amd64"
    chmod +x "$binary_file"

``` 

### 准备clash配置文件

    生成配置文件
```
    python3 .\update.py --sub https://your.sub.addr
```
    如果有两个订阅地址，第二个作为备份：
```
    python3 .\update.py --sub https://your.subscribe.addr --bak https://your.backup.scribe.addr
```
    生成的配置文件为config.yaml,如何想自定义，可以先修改config_tpl.yaml再重新生成
    

### 一键配置
    如果已经是root权限，则不需要使用sudo了：
```
    sudo ./install.sh
```
    

    该脚本执行以下内容：
    1. 关闭原有dns服务
    2. 配置iptables
    3. 配置clash服务并启动

    自己修改iptables可以先执行`./clean_iptables_v4_v6.sh`,再执行`./iptables_v4_v6.sh`。
    可以使用`service clash stop` 关闭服务，`service clash start`开启服务 `service clash restat`重启服务

### 控制面板

    本项目自带了控制面板，执行完`install.sh`可以直接打开`http://{your.ip}:9090/ui`,这里用的ip就是ubuntu的ip
    本项目使用的是yacd的dashbard，是一个比较旧的版本，无需部署即可使用
    在控制面板上，设置想要使用的代理


### 路由器设置

    小米路由器后台管理页面基本一致：
    常用设置->局域网设置->DHCP服务，修改DNS和网关ip为透明代理网关ip，二者需要在一个网段
    建议透明代理绑定静态ip，防止ip变化导致无法上网

### ipv6设置：

    如果没有ipv6的需求，可以免除这一步，如果想看ipv6的iptv，就可以参考以下。
    由于ipv6的ip都是公网ip，且子网网段的分配都受限于运营商，一般情况下，家庭宽带无法使用静态ipv6配置，这就意味着我们没法手动设置网关。
    如果上网方式设置了Native模式，那么网关一定是路由器本身，这就会导致翻墙时，支持ipv6的网站没有经过透明代理网关，无法正常上网。
    由于我们的clash中使用了fake-ip的dns服务，所以我们只要把ipv6的dns服务地址设置成透明代理网关的ip即可，这样我们设备获得的ip6就是fake-ip提供的，上网一定会经过透明代理网关。
    设置ipv6的dns服务器存在一个问题，即家庭宽带ipv6局域网前缀是会经常变动的，导致透明代理网关的ipv6地址也是变化的，所以我们没法填写一个固定的ipv6地址作为ipv6的dns服务器地址。此时我们可以利用6to4解决这个问题。
    下面介绍小米路由器如何设置
    1. 首先将透明代理ip转换为ipv6地址，例如：192.168.31.2 - > ::ffff:C0A8:1F02，具体规则可以自行百度
    2. 上网方式选择Native，防火墙保持开启
    3. DNS选择手动配置DNS，输入::ffff:C0A8:1F02,此时提示`IPv6地址由8组四个十六进制数组成，每组之间用:区隔`
    4. 由于路由器页面对地址格式做了不必要的校验，我们可以按F12，选择network窗口，随便填一个正确的dns地址，例如2402:4e00::,点击应用，找到set_wan6这个请求：右键复制为powershell

```
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
    $session.Cookies.Add((New-Object System.Net.Cookie("__guid", "...3228", "/", "192.168.31.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("psp", "admin|||2|||0", "/", "192.168.31.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("monitor_count", "13", "/", "192.168.31.1")))
    Invoke-WebRequest -UseBasicParsing -Uri "http://192.168.31.1/cgi-bin/luci/;stok=/api/xqnetwork/set_wan6" `
    -Method "POST" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json, text/javascript, */*; q=0.01"
    "Accept-Encoding"="gzip, deflate"
    "Accept-Language"="zh-CN,zh;q=0.9"
    "Origin"="http://192.168.31.1"
    "Proxy-Authorization"="Basic c3ZlbjoyMDA0MTIwNzA="
    "X-Requested-With"="XMLHttpRequest"
    } `
    -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
    -Body "wanType=native&autosetipv6=1&dns1=2402%3A4e00%3A%3A1&dns2="
```
    
    将上面的dns1=2402%3A4e00%3A%3A1&dns2=替换为dns1=%3A%3Affff%3AC0A8%3A1F02&dns2=

    然后打开windows powershell命令行，输入上面的代码即可，刷新路由器管理页面，发现DNS已经设置为::ffff:C0A8:1F02。
    无论ipv6局域网前缀如何变化，::ffff:C0A8:1F02这个地址都指向了透明代理ip地址。
