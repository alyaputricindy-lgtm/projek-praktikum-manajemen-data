#!/bin/bash

# ============================================================
# etl_solution.sh - ETL Pipeline Data Transaksi
# ============================================================

BASE_DIR="$HOME/etl"
INPUT_FILE="$BASE_DIR/data/transactions.txt"
OUTPUT_FILE="$BASE_DIR/data/processed_transactions.log"
LOG_FILE="$BASE_DIR/logs/etl.log"
ERR_FILE="$BASE_DIR/logs/etl_error.log"
LOCK_FILE="$BASE_DIR/lock/etl.lock"
OFFSET_FILE="$BASE_DIR/lock/etl.offset"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log_info()  { echo "[$TIMESTAMP] [INFO]  $1" >> "$LOG_FILE"; }
log_error() { echo "[$TIMESTAMP] [ERROR] $1" >> "$ERR_FILE"; }

cleanup() { rm -f "$LOCK_FILE"; log_info "Lock dihapus. Selesai."; }
trap cleanup EXIT

# STEP 1: Cek lock file
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        log_error "ETL masih berjalan (PID: $PID). Skip."
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"
log_info "====== ETL Dimulai (PID: $$) ======"

# STEP 2: Validasi file input
if [ ! -f "$INPUT_FILE" ]; then
    log_error "File input tidak ditemukan."
    exit 1
fi
if [ ! -s "$INPUT_FILE" ]; then
    log_info "File input kosong. Skip."
    exit 0
fi

# STEP 3: Incremental - baca offset
LAST_OFFSET=0
[ -f "$OFFSET_FILE" ] && LAST_OFFSET=$(cat "$OFFSET_FILE")
TOTAL_LINES=$(wc -l < "$INPUT_FILE")

if [ "$LAST_OFFSET" -ge "$TOTAL_LINES" ]; then
    log_info "Tidak ada data baru. Skip."
    exit 0
fi

log_info "Memproses baris $((LAST_OFFSET + 1)) sampai $TOTAL_LINES"
NEW_DATA=$(tail -n +$((LAST_OFFSET + 1)) "$INPUT_FILE")

# STEP 4: Transform - uppercase + filter > 100000
TRANSFORMED=$(echo "$NEW_DATA" | awk -F',' '{
    amount = $3
    gsub(/[^0-9]/, "", amount)
    if (amount + 0 > 100000) print toupper($0)
}')

if [ -z "$TRANSFORMED" ]; then
    log_info "Tidak ada transaksi > 100.000."
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
    exit 0
fi

# STEP 5: Load ke output
echo "$TRANSFORMED" >> "$OUTPUT_FILE"
echo "$TOTAL_LINES" > "$OFFSET_FILE"
log_info "Berhasil. $(echo "$TRANSFORMED" | wc -l) transaksi disimpan."
log_info "====== ETL Selesai ======"
