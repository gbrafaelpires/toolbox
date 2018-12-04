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
            if [ -n "$result" ] && [ "$result" = false ]; then
                echo -e "\033[0;34m$2 \033[0mencontrado :)"
            else
                echo -e "\033[0;31m$2 \033[0mnão encontrado :("
                return 1
            fi
    fi
}

# Apresentando um cluster
preseting_cluster(){
    searching_cluster "$1" "$2"
    if [ "$?" -eq 1 ]; then
        return 1
    else
        name=$(aws ecs describe-clusters --region "$1" --cluster "$2" | jq -r '.clusters[].clusterName')
        instancescount=$(aws ecs describe-clusters --region "$1" --cluster "$2" | jq -r '.clusters[].registeredContainerInstancesCount')
        runningtaskscount=$(aws ecs describe-clusters --region "$1" --cluster "$2" | jq -r '.clusters[].runningTasksCount')
        activeservicescount=$(aws ecs describe-clusters --region "$1" --cluster "$2" | jq -r '.clusters[].activeServicesCount')
            if [ -n "$name" ] && [ -n "$instancescount" ] && [ -n "$runningtaskscount" ] && [ -n "$activeservicescount" ]; then  
                echo "Nome|Total de Instâncias Registradas|Total de Containers em Execução|Total de Aplicações Registradas" > output.txt
                echo "$name|$instancescount|$runningtaskscount|$activeservicescount" >> output.txt
                echo ""
                echo -e "--- \033[0;32mInformações do Cluster \033[0m---\033[0m"
                cat "$PWD"/output.txt | column -t -s "|"
                echo ""
            else
                echo "Ops, algum erro inesperado aconteceu :("
                return 1
            fi
    fi
}

# Listando os clusters de uma região específica
listing_clusters(){
    searching_region "$1"
    if [ "$?" -eq 0 ]; then
        clusters=(`aws ecs list-clusters --region "$1" | jq -r '.clusterArns[]' | cut -d'/' -f2`)
            if [ -n "$clusters" ]; then
                echo -e "Cluster(s) disponíveis em \033[0;34m$1:\033[0m"
                for cluster in "${clusters[@]}"; do
                    echo "- $cluster"
                done
            else
               echo "Nenhum cluster encontrado :("
               return 1
            fi
    fi
}

# Status do cluster
status_of_cluster(){
    searching_cluster "$1" "$2"
        if [ "$?" -eq 0 ]; then 
            condition=$(aws ecs describe-clusters --cluster "$2" | jq -r '.clusters[].status')
                if [ -n "$condition" ] && [ "$condition" = "ACTIVE" ]; then
                    echo -e "\033[0;34m$2 \033[0mestá ativo :)"
                else
                    echo -e "\033[0;31m$2 \033[0mnão está ativo :("
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
            services=(`aws ecs list-services --region "$1" --cluster "$2" | jq -r '.serviceArns[]' | cut -d'/' -f2 | sort`)
                if [ -n "$services" ]; then
                    echo -e "Aplicações em execução no cluster \033[0;34m$2:\033[0m"
                    for service in "${services[@]}"; do
                        echo "- $service"
                    done
                else
                    echo "Nenhuma aplicação em execução :("
                    return 1
                fi          
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
            if [ -n "$apps" ]; then
                for app in "${apps[@]}"; do
                    if [[ "$app" =~ ^"$3".*$ ]]; then
                        echo "$app" >> apps.txt
                    fi
                done
                if [ -f "$PWD/apps.txt" ]; then
                    echo -e "\033[0;34m$3 \033[0mencontrada :)"
                else
                    echo -e "\033[0;31m$3 \033[0mnão encontrada :("
                    return 1
                fi
            else
                echo "Nenhuma aplicação em execução :("
                return 1
            fi
    fi
}

# Apresentando um serviço
preseting_service(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            if [ -n "$apps" ]; then
                for app in "${apps[@]}"; do
                    if [[ "$app" =~ blue$ ]] || [[ "$app" =~ green$ ]]; then
                        entrie=${app%-*}
                            if [[ "$entrie" =~ .*ecs.* ]]; then
                                entrie=${entrie%-*}
                            fi
                            if [[ "$2" =~ public$ ]]; then
                                getting_hostname "$1" "$DOMAIN" "false" "$entrie" "sim" >/dev/null 2>&1
                                    if [ "$?" -eq 0 ]; then
                                        preseting="full"
                                        formating_output "$1" "$2" "$preseting"
                                    else
                                        getting_hostname "$1" "$DOMAIN" "false" "$entrie" "não" >/dev/null 2>&1
                                            if [ "$?" -eq 0 ]; then
                                                preseting="full"
                                                formating_output "$1" "$2" "$preseting"
                                            fi
                                    fi
                            else
                                getting_hostname "$1" "$DOMAIN" "true" "$entrie" "sim" >/dev/null 2>&1
                                preseting="full"
                                formating_output "$1" "$2" "$preseting"
                            fi
                    else
                        service_features "$1" "$2" "$app" >/dev/null 2>&1
                            if [ "$?" -eq 0 ]; then
                                getting_hostname "$1" "$DOMAIN" "true" "$app" "não" >/dev/null 2>&1
                                    if [ "$?" -eq 0 ]; then
                                        preseting="partial"
                                        formating_output "$1" "$2" "$preseting"
                                    fi
                            else
                                preseting="basic"
                                formating_output "$1" "$2" "$preseting"
                            fi
                    fi
                done
            else
                echo "Ops, algum erro inesperado aconteceu :("
                return 1
            fi   
    else
        echo "Ops, algum erro inesperado aconteceu :("
        return 1
    fi
}

# Status do serviço
status_of_service(){
    searching_service "$1" "$2" "$3"
    if [ "$?" -eq 1 ]; then
        return 1
    elif [ -f "$PWD/apps.txt" ]; then
        apps=(`cat "$PWD"/apps.txt`)
            if [ -n "$apps" ]; then
                for app in "${apps[@]}"; do
                    condition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
                        if [ -n "$condition" ] && [ "$condition" = "ACTIVE" ]; then
                            echo "Nome|Status" > output.txt
                            echo "$app|$condition" >> output.txt
                            echo ""
                            echo -e "--- \033[0;32mInformações da Aplicação \033[0m---\033[0m"
                            cat "$PWD"/output.txt | column -t -s "|"
                            echo ""
                        else
                            echo -e "\033[0;31m$app \033[0mnão está ativo :("
                            return 1
                        fi
                done
            else
                echo "Ops, algum erro inesperado aconteceu :("
                return 1
            fi
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
                            if [ "$name" = "null" ]; then
                                name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
                                | jq -r '.services[].loadBalancers[].loadBalancerName')
                                echo "Esta aplicação possui um ELB :)"
                                echo "Nome: $name"
                            else
                                echo "Esta aplicação possui um ALB e um TG :)"
                                echo "Nome: $name"
                            fi
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
                        echo "$app|$version" >> output.txt
                        echo ""
                        echo -e "--- \033[0;32mInformações da Aplicação \033[0m---\033[0m"
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