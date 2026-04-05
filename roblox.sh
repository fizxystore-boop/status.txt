#!/system/bin/sh

# ==========================================
# ROBLOX MANAGER BY FIZXY (REMOTE CONTROL)
# ==========================================

# --- CONFIG REMOTE (Ganti link di bawah dengan link RAW status.txt lu) ---
URL_CONTROL="https://raw.githubusercontent.com/fizxystore-boop/termux-control/main/status.txt"

# Fungsi Cek Status dari GitHub
check_status() {
    # Ambil status, hapus spasi/newline (tr)
    STATUS=$(curl -s "$URL_CONTROL" | tr -d '[:space:]')
    if [ "$STATUS" = "OFF" ]; then
        echo -e "\n[!] SCRIPT DINONAKTIFKAN OLEH OWNER (FIZXY)."
        # Opsi: Matikan semua roblox sebelum exit
        for PKG in $APPS; do su -c "am force-stop $PKG"; done
        exit 1
    fi
}

# --- PROSES LOGIN / INPUT LINK ---
clear
echo "=========================================="
echo "      ROBLOX MANAGER BY FIZXY             "
echo "=========================================="

# Cek status sebelum minta input
check_status

echo "[*] Menunggu input Private Server..."
read -p "[?] Masukkan Link Private Server Kalian: " USER_LINK

if [ -z "$USER_LINK" ]; then
    echo "[!] Link tidak boleh kosong!"
    exit 1
fi

LINK="$USER_LINK"
APPS=$(pm list packages | grep "com.roblox.fizx" | cut -d ":" -f2)
TIMER=$(date +%s)

set_screen() {
    echo "[*] Setting density..."
    su -c "wm density 164"
    sleep 1
    su -c "service call window 101 i32 20"
}

run_setup() {
    # Setiap kali setup ulang, cek status lagi biar aman
    check_status
    set_screen
    IDX=0

    TOP_LIST="50 300 550 800 1050"  
    BOTTOM_LIST="275 525 775 1025 1275"  

    for PKG in $APPS; do  
        TOP=$(echo $TOP_LIST | cut -d " " -f$((IDX+1)))  
        BOTTOM=$(echo $BOTTOM_LIST | cut -d " " -f$((IDX+1)))  

        echo "[>] Opening $PKG"  
        su -c "monkey -p $PKG -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1  
        sleep 5  

        su -c "input keyevent 3"; sleep 0.5  
        su -c "input keyevent 187"; sleep 1.5  
        su -c "input tap 364 125"; sleep 0.8  
        su -c "input tap 357 343"; sleep 1  

        su -c "input swipe 300 250 680 250 600"  
        sleep 1  

        su -c "input swipe 540 50 540 $TOP 300"  
        sleep 0.6  
        su -c "input swipe 540 275 540 $BOTTOM 300"  
        sleep 1.2  

        IDX=$((IDX + 1))  
    done  

    su -c "monkey -p com.termux -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1  
    sleep 2  

    for PKG in $APPS; do  
        echo "[>] Joining $PKG to Private Server"  
        su -c "monkey -p $PKG -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1  
        sleep 2  
        su -c "am start -a android.intent.action.VIEW -d '$LINK' -p $PKG" > /dev/null 2>&1  
        sleep 12  
    done
}

# Cek apakah package ditemukan
if [ -z "$APPS" ]; then
    echo "[!] No Roblox packages found (com.roblox.fizx*)"
    exit
fi

run_setup

# --- LOOPING MONITORING ---
while true; do
    # Cek status ke GitHub setiap kali loop berjalan (per 15 detik)
    check_status
    
    RESET=0
    NOW=$(date +%s)

    # Auto Clear Cache setiap 5 menit
    if [ $((NOW - TIMER)) -ge 300 ]; then  
        echo "[*] Clearing Cache..."
        for PKG in $APPS; do  
            su -c "rm -rf /data/data/$PKG/cache/*" > /dev/null 2>&1  
        done  
        TIMER=$NOW  
    fi  

    # Monitoring Force Close
    for PKG in $APPS; do  
        CHECK=$(su -c "dumpsys activity activities | grep 'mResumedActivity' | grep $PKG")  
        if [ -z "$CHECK" ]; then  
            echo "[!] FC Detected: $PKG"  
            RESET=1  
            break  
        fi  
    done  

    if [ $RESET -eq 1 ]; then  
        sleep 5  
        for PKG in $APPS; do su -c "am force-stop $PKG"; done  
        sleep 2  
        su -c "input keyevent 3"; sleep 1  
        su -c "input keyevent 187"; sleep 2  

        for i in 1 2 3 4 5; do  
            su -c "input swipe 540 1000 540 100 250"  
            sleep 0.5  
        done  

        su -c "input keyevent 3"; sleep 1  
        run_setup  
        continue  
    fi  

    echo "[$(date +%T)] Monitoring Instances (Status: ONLINE)"  
    sleep 15
done
