#!/bin/bash


interval=1
monitor_memory() {
    echo "=============================================" >> $memory_usage_file
    local python_pid="$1"

    local total_memory_usage_kb=0
    local peak_memory_usage_kb=0
    local count=0
    while ps -p $python_pid > /dev/null; do
        local memory_usage_kb=$(ps -o rss= -p $python_pid)
        local memory_usage_mb=$(echo "scale=2; $memory_usage_kb / 1024" | bc)
        local current_time=$(date +'%Y-%m-%d %H:%M:%S')
        total_memory_usage_kb=$((total_memory_usage_kb + memory_usage_kb))
        if [ $memory_usage_kb -gt $peak_memory_usage_kb ]; then
            peak_memory_usage_kb=$memory_usage_kb
        fi
        count=$((count + 1))
        sleep $interval
    done
    if [ $count -gt 0 ]; then
        local average_memory_usage_kb=$((total_memory_usage_kb / count))
        local average_memory_usage_mb=$(echo "scale=2; $average_memory_usage_kb / 1024" | bc)
    else
        local average_memory_usage_mb=0
    fi
    echo "平均内存占用: $average_memory_usage_mb MB" >> $memory_usage_file
    echo "峰值内存占用: $((peak_memory_usage_kb / 1024)) MB" >> $memory_usage_file
    echo "=============================================" >> $memory_usage_file
}

DATASETS=("uk-2002" "arabic-2005" "it-2004" "webbase-2001")

PARTITIONS=("16")

for DATASET in "${DATASETS[@]}"; do

    FILEPATH="/raid/wsy/tc/${DATASET}.txt"
    memory_usage_file="mem_dbhjava_${DATASET}.txt"

    for PARTITION in "${PARTITIONS[@]}"; do
        SAVENAME_BASE="/raid/wsy/tmp/dbhjava/${PARTITION}/${DATASET}/"
        mkdir -p ${SAVENAME_BASE}
        SAVENAME="${SAVENAME_BASE}$(basename ${FILEPATH%.*})"

        echo "Processing file: ${FILEPATH}"
        echo "Partition: ${PARTITION}"
        echo "Save name: ${SAVENAME}"

        java -Xms1024m -Xmx600g -jar dist/VGP.jar ${FILEPATH} ${PARTITION} -algorithm dbh -threads 64 -output ${SAVENAME} &
        lastPid=$!
        monitor_memory $lastPid
    done
done

