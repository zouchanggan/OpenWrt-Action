#!/bin/bash

sed -i 's/O2/O2 -march=x86-64-v2/g' include/target.mk

# libsodium
sed -i 's,no-mips16 no-lto,no-mips16,g' feeds/packages/libs/libsodium/Makefile

echo '#!/bin/sh
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

if ! grep "Default string" /tmp/sysinfo/model > /dev/null; then
    echo should be fine
else
    echo "Generic PC" > /tmp/sysinfo/model
fi

status=$(cat /sys/devices/system/cpu/intel_pstate/status)

if [ "$status" = "passive" ]; then
    echo "active" | tee /sys/devices/system/cpu/intel_pstate/status
fi

exit 0
'> ./package/base-files/files/etc/rc.local

# Vermagic
curl -s https://downloads.openwrt.org/releases/24.10.1/targets/x86/64/openwrt-24.10.1-x86-64.manifest \
| grep "^kernel -" \
| awk '{print $3}' \
| sed -n 's/.*~\([a-f0-9]\+\)-r[0-9]\+/\1/p' > vermagic
sed -i 's#grep '\''=\[ym\]'\'' \$(LINUX_DIR)/\.config\.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)/\.vermagic#cp \$(TOPDIR)/vermagic \$(LINUX_DIR)/.vermagic#g' include/kernel-defaults.mk

find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

# adguardhome
mkdir -p files/usr/bin
AGH_CORE=$(curl -sL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep /AdGuardHome_linux_amd64 | awk -F '"' '{print $4}')
wget -qO- $AGH_CORE | tar xOvz > files/usr/bin/AdGuardHome
chmod +x files/usr/bin/AdGuardHome

# openclash
mkdir -p files/etc/openclash/core
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
wget -qO- $CLASH_META_URL | tar xOvz > files/etc/openclash/core/clash_meta
wget -qO- $GEOIP_URL > files/etc/openclash/GeoIP.dat
wget -qO- $GEOSITE_URL > files/etc/openclash/GeoSite.dat
chmod +x files/etc/openclash/core/clash*

# caddy
mkdir -p files/usr/bin
CADDY_URL="https://github.com/lmq8267/caddy/releases/download/v2.10.0/caddy-amd64-upx"
wget -qO- $CADDY_URL > files/usr/bin/caddy
chmod +x files/usr/bin/caddy

# 默认设置
git clone --depth=1 -b openwrt-24.10 https://github.com/oppen321/default-settings package/default-settings

# distfeeds.conf
mkdir -p files/etc/opkg
cat > files/etc/opkg/distfeeds.conf <<EOF
src/gz openwrt_base https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/packages/x86_64/base
src/gz openwrt_luci https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/packages/x86_64/luci
src/gz openwrt_packages https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/packages/x86_64/packages
src/gz openwrt_routing https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/packages/x86_64/routing
src/gz openwrt_telephony https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/packages/x86_64/telephony
src/gz openwrt_core https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/24.10.1/targets/x86/64/kmods/6.6.86-1-af351158cfb5febf5155a3aa53785982
EOF

exit 0
