#!/bin/bash

# ============================================================
# analyze_log.sh - Analisis Log Aktivitas Harian
# ============================================================

BASE_DIR="$HOME/etl2"
LOG_FILE="$BASE_DIR/logs/user_activity.log"
REPORT_FILE="$BASE_DIR/logs/daily_report.txt"
ALERT_FILE="$BASE_DIR/logs/alert.log"
TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# ─── STEP 1: Cek file log ada & tidak kosong ────────────────
if [ ! -f "$LOG_FILE" ]; then
    echo "[$NOW] ERROR: File log tidak ditemukan: $LOG_FILE" >> "$ALERT_FILE"
    exit 1
fi

if [ ! -s "$LOG_FILE" ]; then
    echo "[$NOW] ERROR: File log kosong." >> "$ALERT_FILE"
    exit 1
fi

# ─── STEP 2: Filter hanya log hari ini ──────────────────────
TODAY_LOG=$(grep "^$TODAY" "$LOG_FILE")

if [ -z "$TODAY_LOG" ]; then
    echo "[$NOW] INFO: Tidak ada log untuk hari ini ($TODAY)." >> "$ALERT_FILE"
    exit 0
fi

# ─── STEP 3: Hitung statistik ───────────────────────────────
# Total login gagal
FAILED_LOGIN=$(echo "$TODAY_LOG" | grep "ACTION=login" | grep "STATUS=FAILED" | wc -l)

# Total upload sukses
SUCCESS_UPLOAD=$(echo "$TODAY_LOG" | grep "ACTION=upload" | grep "STATUS=SUCCESS" | wc -l)

# Top 3 user paling aktif
TOP_USERS=$(echo "$TODAY_LOG" | \
    grep -oP 'USER=\K[^|]+' | \
    tr -d ' ' | \
    sort | uniq -c | \
    sort -rn | \
    head -3)

# ─── STEP 4: Buat laporan ───────────────────────────────────
{
echo "======================================"
echo "DAILY ACTIVITY REPORT"
echo "Tanggal: $TODAY"
echo "======================================"
echo "Total login gagal  : $FAILED_LOGIN"
echo "Total upload sukses: $SUCCESS_UPLOAD"
echo ""
echo "Top 3 user paling aktif:"
RANK=1
while IFS= read -r line; do
    COUNT=$(echo "$line" | awk '{print $1}')
    USER=$(echo "$line" | awk '{print $2}')
    echo "  $RANK. $USER - $COUNT aktivitas"
    RANK=$((RANK + 1))
done <<< "$TOP_USERS"
echo "======================================"
} > "$REPORT_FILE"

# ─── STEP 5: Kirim alert jika login gagal > 10 ──────────────
if [ "$FAILED_LOGIN" -gt 10 ]; then
    echo "[$NOW] ALERT: Terjadi $FAILED_LOGIN kali login gagal hari ini!" >> "$ALERT_FILE"
fi

echo "[$NOW] INFO: Laporan berhasil dibuat." >> "$ALERT_FILE"
echo "Selesai! Cek laporan di: $REPORT_FILE"
