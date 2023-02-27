#!/bin/bash
# https://blog.ip2location.com/knowledge-base/how-to-block-ip-addresses-from-a-country-using-ipset/
# China, Africa, India, Russia, Brazil
# Blocked from server addresses... download manually.
#https://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone
#https://www.ipdeny.com/ipblocks/data/aggregated/cf-aggregated.zone
#https://www.ipdeny.com/ipblocks/data/aggregated/in-aggregated.zone
#https://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone
#https://www.ipdeny.com/ipblocks/data/aggregated/br-aggregated.zone

# Take our raw list of IPs and convert to an ipset script with sed
sed -i '/^#/d' bad-countries-v4.sh
sed -i 's/^/ipset add countryblocker-v4 /g' bad-countries-v4.sh
sed  -i '1i ipset create countryblocker-v4 nethash' bad-countries-v4.sh
chmod +x bad-countries-v4.sh
bash bad-countries-v4.sh

sed -i '/^#/d' bad-countries-v6.sh
# For IPv6 the first line needs to be
sed -i 's/^/ipset add countryblocker-v6 /g' bad-countries-v6.sh
sed  -i '1i ipset create countryblocker-v6 hash:net family inet6' bad-countries-v6.sh
chmod +x bad-countries-v6.sh
bash bad-countries-v6.sh

# Save both into a file we can restore as
ipset save > /root/country-blockers.ipset
# Then restore like this on boot. You'd need to restore your iptables
# a bit after this, cron runs stuff in parallel.
ipset restore < /root/country-blockers.ipset
