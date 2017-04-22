#!/bin/bash

# This script is intended to look for appropriate location in a gcode file to enter the following:
# G28 X Y (home X and Y)
# G1 Z<height in mm> (move to the Z height you decide for filament changing)
# M0 (pause)
# G1 Z<next layer mm minus layer height> (move to the previous Z height)

# This allows you to swap filament at a desired height and homes X and Y so we can later return to the same position
# In addition, I've had to remove the following line at the layer will resuming will take place
# G1 E0.0000
# I believe this line causes the extruder to try to reset to 0 by spinning backwards. This unloads the filament loaded during the pause

# Use like:
# ./pause_at_layer <layer> <layer height to 3 decimal places> <z height for filament change to 3 decimal places> <file>
# Example:
# ./pause_at_layer 10 0.200 20.000 fidget_spinner.stl

# For multiple layers at once you can do
# for layer in 8 14 23 29; do ~/pause_at_layer.bash ${layer} 0.200 20.000 fidget_spinner.gcode; done

# Check to make sure provided file is a file
if ! [ -f "${4}" ]; then
  echo "Not a valid file, ${4}"
  exit 1
fi

# Make sure layer is an integer
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Invalid layer, ${1}"
  exit 1
fi

# Make sure layer height is valid number with decimals
if ! [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Invalid layer height, ${2}"
  exit 1
fi

# Make sure stop height is valid number with decimals
if ! [[ "$3" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Invalid stop height, ${3}"
  exit 1
fi

# Get the target layer position
z_pos=$( echo "${1} * ${2}" | bc )
# Get the position of insertion in the code
gcode_pos=$( grep "; layer ${1}," ${4} )

# Make insertion
sed -i "/G1 Z${z_pos}/,/G1 E0.0000/d" ${4}
sed -i "s/${gcode_pos}/${gcode_pos}\n; FILAMENT CHANGE added by Pause At Layer\nG28 X Y\nG1 Z${3}\nM0\nG1 Z${z_pos}\n; END FILAMENT CHANGE/" ${4}

# Show location of inserted code
grep -C 6 "; layer ${1}" ${4}
