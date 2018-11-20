#!/usr/bin/env bash

### Região ###

# Procurando uma região
searching_region(){
    if [ -z "$1" ]; then
        echo "Esta função necessita do nome da região :)"
        return 1
    else
        regions=(`aws ec2 describe-regions | jq -r '.Regions[].RegionName'`)
        found=0
            for region in "${regions[@]}"; do
                if [ "$1" = "$region" ]; then
                    found=$((found+1))
                fi
            done
            if [ "$found" -eq 1 ]; then
                echo -e "\033[0;34m$1 \033[0mé uma região válida :)"
            else
                echo -e "\033[0;31m$1 \033[0mnão é uma região válida :("
                return 1
            fi
    fi
}

###