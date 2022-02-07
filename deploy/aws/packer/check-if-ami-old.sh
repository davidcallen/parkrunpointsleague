#!/bin/bash
# Check if latest AMI is out-of-date compared to the local packer and ansible files
# This is an indication you want to rebuild the AMI.
# Useful during packer/terraform development and debugging.
#
find . -type f -printf '%T@ %p\n' | awk '
    BEGIN { mostrecenttime = 0; mostrecentline = "nothing"; }
    {
        if ($1 > mostrecenttime)
            { mostrecenttime = $1; mostrecentline = $0; }
    }
    END { print strftime("%Y-%m-%d %H:%m:%S", mostrecenttime); print mostrecentline; }'

    # | cut -f2- -d ' '