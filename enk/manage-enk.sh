#!/bin/bash

# Set pwd variable
export PWD=$(pwd)

# Loading support scripts
source "$PWD"/support.sh || {
    echo "Este arquivo é o mínimo que precisamos para executar o ENK :)"
    return 1
}

# Loading support scripts
load_support_scripts(){
    source "$PWD"/support/colors.sh
    source "$PWD"/support/run-containers.sh
}

# Containers
ES=$(grep -i "elasticsearch" "$PWD"/support/containers.txt)
KB=$(grep -i "kibana" "$PWD"/support/containers.txt)
NX=$(grep -i "nginx" "$PWD"/support/containers.txt)
containers=( "$ES" "$KB" "$NX" )

# Start ENK
start_enk(){
    for container in "${containers[@]}"; do
        get_running_container "$container"
        if [ "$?" -eq 1 ]; then
            get_exited_container "$container"
            if [ "$?" -eq 1 ]; then
                remove_container "$container"
                run-containers "$container"
            else
                run-containers "$container"
            fi
        fi
    done
}

# Stop ENK
stop_enk(){
    for container in "${containers[@]}"; do
        get_running_container "$container"
        if [ "$?" -eq 0 ]; then
            kill_container "$container"
            remove_container "$container"
        fi
    done
}

# Start script
verify_dep_files
check_dep_installed
load_support_scripts
