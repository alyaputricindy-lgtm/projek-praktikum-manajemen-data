#!/bin/bash
# Skip ETL kalau jam 12.00 - 12.59 (jam sibuk)

HOUR=$(date +%H)

if [ "$HOUR" -eq 12 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] JAM SIBUK - ETL dilewati" \
        >> ~/etl/logs/etl.log
    exit 0
fi

~/etl/etl_solution.sh
