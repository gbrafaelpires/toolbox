#!/usr/bin/env bash

# Carregando funções base
source "$PWD/base.sh"

# Procurando um domínio
searching_domain(){
    searching_region "$1"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$2" ]; then
        echo "Esta função necessita do nome do domínio, inclusive com o ponto no final :)"
        return 1
    elif [ -z "$3" ]; then
        echo "Este domínio é privado? Opções: true ou false :)"
        return 1
    else
        name=$(aws route53 list-hosted-zones-by-name --region "$1" \
        | jq -r '.HostedZones[] | select(.Name=="'$2'") | select(.Config.PrivateZone=='$3') | .Name')
            if [ -n "$name" ]; then
                echo -e "\033[0;34m$2 \033[0mencontrado :)"
            else
                echo -e "\033[0;31m$2 \033[0mnão encontrado :("
                return 1
            fi
    fi
}

# Obtendo o hosted zone ID de um domínio
getting_hostedzoneid(){
    searching_region "$1"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$2" ]; then
        echo "Esta função necessita do nome do domínio, inclusive com o ponto no final :)"
        return 1
    elif [ -z "$3" ]; then
        echo "Este domínio é privado? Opções: true ou false :)"
        return 1
    else
        id=$(aws route53 list-hosted-zones-by-name --region "$1" \
        | jq -r '.HostedZones[] | select(.Name=="'$2'") | select(.Config.PrivateZone=='$3') | .Id' \
        | cut -d'/' -f3)
            if [ -n "$id" ]; then
                echo "\033[0;34m$id \033[0mencontrado :)"
            else
                echo "Nenhum ID encontrado :("
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
        getting_hostedzoneid "$1" "$2" "$3" >/dev/null 2>&1
            dnsname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$id" \
            | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | .Name')
                if [ -n "$dnsname" ]; then
                    echo -e "\033[0;34m$4 \033[0mencontrada :)"
                else
                    echo -e "\033[0;31m$4 \033[0mnão encontrada :("
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
        getting_hostedzoneid "$1" "$2" "$3" >/dev/null 2>&1
            if [[ "$5" =~ [Ss][Ii][Mm] ]]; then
                identifier="ECS-BLUE"
                hostname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$id" \
                | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | select(.SetIdentifier=="'$identifier'") | .Name')
                    if [ -n "$hostname" ]; then
                        return 0
                    else
                        echo "Esta aplicação não está em Blue/Green :)"
                        return 1
                    fi
            elif [[ "$5" =~ [Nn][Ãã][Oo] ]]; then
                hostname=$(aws route53 list-resource-record-sets --region "$1" --hosted-zone-id "$id" \
                | jq -r '.ResourceRecordSets[] | select(.Name=="'$4.$2'") | .Name' | uniq)
                    if [ -n "$hostname" ]; then
                        return 0
                    else
                        echo "Ops, algum erro inesperado aconteceu :("
                        return 1
                    fi
            else
                echo "Opção \033[0;31m$5 \033[0minválida :("
                return 1
            fi
    fi
}