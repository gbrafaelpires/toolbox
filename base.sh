#!/usr/bin/env bash

### DNS ###

# Procurando uma região
searching_region(){
    if [ -z "$1" ]; then
        echo "Esta função necessita do nome da região :)"
        return 1
    else
        region=$(aws ec2 describe-regions | jq -r '.Regions[] | select(.RegionName=="'$1'") | .RegionName')
            if [ -n "$region" ]; then
                echo -e "\033[0;34m$1 \033[0mencontrada :)"
            else
                echo -e "\033[0;31m$1 \033[0mnão encontrada :("
                return 1
            fi
    fi
}

###

### ECS ###

# Formatando saída

formating_output(){
    if [ -z "$3" ]; then
        return 1
    elif [[ "$3" =~ [Ff][Uu][Ll][Ll] ]]; then
        name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].serviceName')
        loadbalancer=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
        | jq -r '.services[].loadBalancers[].targetGroupArn' \
        | cut -d'/' -f2 | cut -d'/' -f1)
        condition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
        launchtype=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].launchType')
        taskdefinition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
        | jq -r '.services[].taskDefinition' \
        | cut -d'/' -f2 | cut -d':' -f2)
        runningcount=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].runningCount')
        echo "Nome|Nome DNS|ALB|Status|Tipo de Lançamento|Versão em Execução|Containers em Execução" > output.txt
        echo "$name|$hostname|$loadbalancer|$condition|$launchtype|$taskdefinition|$runningcount" >> output.txt
        echo ""
        echo -e "--- \033[0;32mInformações da Aplicação \033[0m---\033[0m"
        cat "$PWD"/output.txt | column -t -s "|"
        echo ""
    elif [[ "$3" =~ [Pp][Aa][Rr][Tt][Ii][Aa][Ll] ]]; then
        name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].serviceName')
        loadbalancer=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
        | jq -r '.services[].loadBalancers[].loadBalancerName' \
        | cut -d'/' -f2 | cut -d'/' -f1)
        condition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
        launchtype=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].launchType')
        taskdefinition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
        | jq -r '.services[].taskDefinition' \
        | cut -d'/' -f2 | cut -d':' -f2)
        runningcount=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].runningCount')
        echo "Nome|Nome DNS|ALB|Status|Tipo de Lançamento|Versão em Execução|Containers em Execução" > output.txt
        echo "$name|$hostname|$loadbalancer|$condition|$launchtype|$taskdefinition|$runningcount" >> output.txt
        echo ""
        echo -e "--- \033[0;32mInformações da Aplicação \033[0m---\033[0m"
        cat "$PWD"/output.txt | column -t -s "|"
        echo ""
    elif [[ "$3" =~ [Bb][Aa][Ss][Ii][Cc] ]]; then
        name=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].serviceName')
        condition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].status')
        launchtype=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].launchType')
        taskdefinition=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" \
        | jq -r '.services[].taskDefinition' \
        | cut -d'/' -f2 | cut -d':' -f2)
        runningcount=$(aws ecs describe-services --region "$1" --cluster "$2" --services "$app" | jq -r '.services[].runningCount')
        echo "Nome|Status|Tipo de Lançamento|Versão em Execução|Containers em Execução" > output.txt
        echo "$name|$condition|$launchtype|$taskdefinition|$runningcount" >> output.txt
        echo ""
        echo -e "--- \033[0;32mInformações da Aplicação \033[0m---\033[0m"
        cat "$PWD"/output.txt | column -t -s "|"
        echo ""
    fi
}

###