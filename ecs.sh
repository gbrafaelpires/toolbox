#!/usr/bin/env bash

# Carregando funções base
source "$PWD/base.sh"
source "$PWD/dns.sh"

# Variáveis esperadas
DOMAIN="guiabolso.in."

### Cluster ##

# Procurando um cluster 
searching_cluster(){
    searching_region "$1"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$2" ]; then
        echo "Esta função necessita do nome do cluster :)"
        return 1
    else
        result=$(aws ecs describe-clusters --region "$1" --cluster "$2" | jq -r '.clusters == []')
            if [ "$result" = false ]; then
                echo -e "Cluster \033[0;34m$2 \033[0mencontrado :)"
            else
                echo -e "Cluster \033[0;31m$2 \033[0mnão encontrado :("
                return 1
            fi
    fi
}

# Listando os clusters de uma região específica
listing_clusters(){
    searching_region "$1"
    if [ "$?" -eq 0 ]; then
        clusters=$(aws ecs list-clusters --region "$1" | jq -r '.clusterArns[]' | cut -d'/' -f2)
            if [ -z "$clusters" ]; then
                echo "Nenhum cluster encontrado :("
                return 1
            else
                echo -e "Clusters disponíveis em \033[0;34m$1:\033[0m"
                echo "$clusters"
            fi
    fi
}

# Status do cluster
status_of_cluster(){
    searching_cluster "$1" "$2"
        if [ "$?" -eq 0 ]; then 
            status=$(aws ecs describe-clusters --cluster "$2" | jq -r '.clusters[].status')
                if [ "$status" = "ACTIVE" ]; then
                    echo -e "Cluster \033[0;34m$2 \033[0mestá ativo :)"
                else
                    echo -e "Cluster \033[0;31m$2 \033[0mnão está ativo :("
                    return 1
                fi
        fi
}

###

### Serviço ###

# Listando os serviços em execução em algum cluster
listing_services(){
    searching_cluster "$1" "$2"
        if [ "$?" -eq 0 ]; then
            echo -e "Aplicações em execução no cluster \033[0;33m$2:\033[0m"
            sleep 5
            aws ecs list-services --region "$1" --cluster "$2" | jq -r '.serviceArns[]' | cut -d'/' -f2 | sort
        fi
}

# Procurando um serviço
searching_service(){
    rm -f "$PWD"/apps.txt || true
    searching_cluster "$1" "$2"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -z "$3" ]; then
        echo "Esta função necessita do nome da aplicação :)"
        return 1
    else
        apps=(`aws ecs list-services --region "$1" --cluster "$2" | jq -r '.serviceArns[]' | cut -d'/' -f2 | sort`)
            for app in "${apps[@]}"; do
                if [[ "$app" =~ ^"$3".*$ ]]; then
                    echo "$app" >> apps.txt
                fi
            done
            if [ -f "$PWD/apps.txt" ]; then
                echo -e "Aplicação \033[0;34m$3 \033[0mencontrada :)"
            else
                echo -e "Aplicação \033[0;31m$3 \033[0mnão encontrada :("
                return 1
            fi
    fi
}

# Apresentando o serviço
preseting_service(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            for app in "${apps[@]}"; do
                if [[ "$app" =~ blue$ ]] || [[ "$app" =~ green$ ]]; then
                    entrie=$(echo "$app" | cut -d'-' -f1)
                    getting_hostname "$1" "$DOMAIN" "true" "$entrie" "sim" >/dev/null 2>&1
                    output_service "$1" "$2"
                else
                    getting_hostname "$1" "$DOMAIN" "true" "$app" "não" >/dev/null 2>&1
                    output_service "$1" "$2"
                fi
            done
    else
        echo "Ops, algum erro inesperado aconteceu :("
        return 1
    fi
}

# Formatando saída
output_service(){
    name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].serviceName')
    loadbalancer=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
    | jq -r '.services[].loadBalancers[].targetGroupArn' \
    | cut -d'/' -f2 | cut -d'/' -f1)
    status=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
    launchtype=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].launchType')
    taskdefinition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
    | jq -r '.services[].taskDefinition' \
    | cut -d'/' -f2 | cut -d':' -f2)
    echo "Nome|Nome DNS|ALB|Status|Tipo de Lançamento|Versão em Execução" > output.txt
    echo "$name|$hostname|$loadbalancer|$status|$launchtype|$taskdefinition" >> output.txt
    echo ""
    echo -e "                        \033[0;33m--- Informações do Aplicação ---\033[0m"
    cat "$PWD"/output.txt | column -t -s "|"
    echo ""
}

# Status do serviço
status_of_service(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            for app in "${apps[@]}"; do
                status=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
                echo "Status da aplicação $app: $status :)"
            done
    else
        echo "Ops, algum erro inesperado aconteceu :("
        return 1
    fi
}

# Verificando se a aplicação possui um ALB e um TG
service_features(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            for app in "${apps[@]}"; do
                result=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].loadBalancers == []')
                    if [ "$result" = false ]; then
                        name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
                        | jq -r '.services[].loadBalancers[].targetGroupArn' | cut -d'/' -f2)
                        echo "Esta aplicação possui um ALB e um TG :)"
                        echo "Nome: $name"
                    else
                        echo "Esta aplicação não possui um ALB e um TG :)"
                        return 1
                    fi
            done
    else
        echo "Ops, algum erro inesperado aconteceu :("
        return 1
    fi
}

###

### Outras funções ###

# Obtendo a última task definition em execução
getting_latest_task_running(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            for app in "${apps[@]}"; do
                taskdefinition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].taskDefinition')
                    if [ -n "$taskdefinition" ]; then
                        version=$(echo $taskdefinition | cut -d'/' -f2 | cut -d':' -f2)
                        echo "Nome|Versão em Execução" > output.txt
                        echo "$app|$taskdefinition" >> output.txt
                        echo ""
                        echo -e "\033[0;33m--- Informações do Aplicação ---\033[0m"
                        cat "$PWD"/output.txt | column -t -s "|"
                        echo ""
                    else
                        echo "Nenhuma task definition em execução :)"
                        return 1
                    fi
            done
    else
        echo "Ops, algum erro inesperado aconteceu :("
        return 1
    fi 
}

###