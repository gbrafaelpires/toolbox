#!/usr/bin/env bash

# Carregando funções base
source "$PWD/base.sh"

# Procurando um domínio válido
searching_domain(){
    searching_region "$1"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$2" ]; then
        echo "Esta função necessita do nome do domínio, inclusive com o ponto no final :)"
        return 1
    elif [ -z "$3" ]; then
        echo "Este domínio é privado ou público? Opções: true ou false :)"
        return 1
    else
        names=(`aws route53 list-hosted-zones-by-name --region "$1" \
        | jq -r '.HostedZones[] | select(.Config.PrivateZone=='$3') | .Name'`)
        found=0
            for name in "${names[@]}"; do
                if [ "$2" = "$name" ]; then
                    found=$((found+1))
                fi
            done
            if [ "$found" -eq 1 ]; then
                echo -e "\033[0;34m$2 \033[0mé um domínio válido :)"
            else
                echo -e "\033[0;31m$2 \033[0mnão é um domínio válido :("
                return 1
            fi
    fi
}

# Buscando entradas de uma aplicação em um domínio válido
searching_entries(){
    searching_domain "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$4" ]; then
        echo "Esta função necessita do nome da aplicação :)"
        return 1
    else
        hostedzoneid=$(aws route53 list-hosted-zones-by-name --region "$1" \
        | jq -r '.HostedZones[] | select(.Config.PrivateZone=='$3') | select(.Name=="'$2'") | .Id' \
        | cut -d'/' -f3)
            if [ -n "$hostedzoneid" ]; then
                dnsname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$hostedzoneid" \
                | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | .Name')
                    if [ -n "$dnsname" ]; then
                        echo -e "Entrada \033[0;34m$4 \033[0mencontrada :)"
                    else
                        echo -e "Entrada \033[0;31m$4 \033[0mnão encontrada :("
                        return 1
                    fi
            else
                echo "Ops, algum erro inesperado aconteceu :("
                return 1
            fi
    fi
}

# Obtendo o nome DNS de uma aplicação em Blue/Green ou não
getting_hostname(){
    searching_entries "$1" "$2" "$3" "$4"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$5" ]; then
        echo "Esta aplicação está em Blue/Green? Opções: sim ou não :)"
        return 1
    else
        hostedzoneid=$(aws route53 list-hosted-zones-by-name --region "$1" \
        | jq -r '.HostedZones[] | select(.Config.PrivateZone=='$3') | select(.Name=="'$2'") | .Id' \
        | cut -d'/' -f3)
            if [ "$5" = "sim" ]; then
                identifier="ECS-BLUE"
                export hostname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$hostedzoneid" \
                | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | select(.SetIdentifier=="'$identifier'") | .Name')
                    if [ -n "$hostname" ]; then
                        echo "$hostname"
                    else
                        echo "Esta aplicação não está em Blue/Green :)"
                        return 1
                    fi
            else
                export hostname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$hostedzoneid" \
                | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | .Name' | uniq)
                    if [ -n "$hostname" ]; then
                        echo "$hostname"
                    else
                        echo "Ops, algum erro inesperado aconteceu :("
                        return 1
                    fi
            fi
    fi
}