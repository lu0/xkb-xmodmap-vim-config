#!/bin/bash

# Put your xmodmap config in xmodmap/xmodmap_latam_defaults.lst
# Run with sudo

setxkbmap -option && setxkbmap latam && \
xmodmap -pke > xmodmap/xmodmap_latam_defaults.lst && \
xkbcomp -xkb $DISPLAY xkb/latam_defaults.xkb && \
setxkbmap -option caps:swapescape && \
xmodmap xmodmap/xmodmap_latam_customs.lst && \
xkbcomp -xkb $DISPLAY xkb/latam_custom.xkb && \
setxkbmap latam && \
sed -n '/^xkb_symbols/, /^xkb_/p' xkb/latam_custom.xkb | head -n -1 > xkb/latam_custom_symbols.xkb && \
prev_header=$(head -1 xkb/latam_custom_symbols.xkb) && \
lang=$(setxkbmap -query | grep layout | cut -d ":" -f 2 | xargs) && \
includes=$(echo $prev_header |  cut -d '"' -f2) && \
echo "xkb_symbols \"${lang}_custom\" {" > tmp.xkb && \
echo -e "\tinclude \"${includes}\"" >> tmp.xkb && \
tail -n +2 xkb/latam_custom_symbols.xkb >> tmp.xkb && \
mv tmp.xkb xkb/latam_custom_symbols.xkb && \
ln -srf xkb/latam_custom_symbols.xkb /usr/share/X11/xkb/symbols/latam_custom && \
setxkbmap latam_custom