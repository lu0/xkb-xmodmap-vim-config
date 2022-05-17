#!/usr/bin/env bash

#
# This scripts converts a custom xmodmap configuration file
# into a system-wide XKB layout and applies it.
#

set -euo pipefail

# Reset layout and remap options to the default ones.
# i.e. no remaps, latam layout.
layout::apply_defaults() {
    setxkbmap -option && setxkbmap latam
}
layout::apply_defaults

# Dump this default layout as an xmodmap file
xmodmap -pke > xmodmap/xmodmap_latam_defaults.lst

# Dump this default layout as an XKB file
xkbcomp -xkb $DISPLAY xkb/latam_defaults.xkb

# Apply any remappings you use, i.e. Caps Lock <-> Escape, for me
setxkbmap -option caps:swapescape

# Apply the customized layout using the custom, readable, xmodmap config file,
# This may take a minute or so.
xmodmap xmodmap/xmodmap_latam_customs.lst

# Dump the just-applied customized layout as an XKB file
xkbcomp -xkb $DISPLAY xkb/latam_custom.xkb

# Get the symbols portion of the applied layout and dump it into a new xkb file.
xkb_symbols_portion=$(
    sed -n '/^xkb_symbols/, /^xkb_/p' xkb/latam_custom.xkb | head -n-1
)
echo "${xkb_symbols_portion}" | sudo tee xkb/latam_custom_symbols.xkb

# Extract remap includes, defined between quotes in xkb_symbols's header
remaps_includes=$(echo "$xkb_symbols_portion" | head -n1 | cut -d'"' -f2)

# Get the name the custom layout is based on
setxkbmap latam # Reset layout to the default one
default_layout_name=$(setxkbmap -query | grep layout | cut -d":" -f2 | xargs)

temp_file=.temp_custom_xkb_layout.xkb

# Build the xkb-like header with the custom information
echo "xkb_symbols \"${default_layout_name}_custom\" {" > ${temp_file}
echo -e "\tinclude \"${remaps_includes}\"" >> ${temp_file}

# Copy generated symbols (except the header).
tail -n +2 xkb/latam_custom_symbols.xkb >> ${temp_file}

# Link the generated XKB file
/usr/bin/env mv -f ${temp_file} xkb/latam_custom_symbols.xkb
sudo ln -srf xkb/latam_custom_symbols.xkb /usr/share/X11/xkb/symbols/latam_custom

# Reset layout and remap options to the default ones, again
layout::apply_defaults

# Apply the new, custom, XKB configuration
setxkbmap latam_custom

# Wait for user confirmation
seconds=15
sleep ${seconds}
read -t ${seconds} -p "Hit ENTER to keep this configuration,
    or wait for a moment to restore your previous configuration" \
    || { echo "Restoring previous configuration..." && layout::apply_defaults ;}

echo "Layout saved, you can reapply it with:"
echo -e "\tsetxkbmap ${default_layout_name}_custom"
