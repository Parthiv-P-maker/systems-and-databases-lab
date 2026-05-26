#!/bin/bash
# =============================================================================
# SysAdmin Toolkit - Interactive CLI System Administration Tool
# Author: Generated Script
# Description: A comprehensive menu-driven system administration utility
# =============================================================================

# -----------------------------------------------------------------------------
# COLOR DEFINITIONS
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# UTILITY FUNCTIONS
# -----------------------------------------------------------------------------

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║          🛠  SysAdmin Toolkit v1.0                   ║"
    echo "  ║        Interactive System Administration CLI         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}══════════════════════════════════════${RESET}"
    echo -e "${WHITE}${BOLD}  $1${RESET}"
    echo -e "${BLUE}${BOLD}══════════════════════════════════════${RESET}\n"
}

print_success() { echo -e "${GREEN}✔  $1${RESET}"; }
print_error()   { echo -e "${RED}✘  $1${RESET}"; }
print_warn()    { echo -e "${YELLOW}⚠  $1${RESET}"; }
print_info()    { echo -e "${CYAN}ℹ  $1${RESET}"; }

pause() {
    echo -e "\n${DIM}Press [Enter] to return to the menu...${RESET}"
    read -r
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        print_warn "This feature requires root privileges. Try: sudo $0"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# 1. SYSTEM INFORMATION
# -----------------------------------------------------------------------------
show_system_info() {
    print_section "System Information"
    echo -e "${YELLOW}Hostname       :${RESET} $(hostname)"
    echo -e "${YELLOW}OS             :${RESET} $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || uname -o)"
    echo -e "${YELLOW}Kernel         :${RESET} $(uname -r)"
    echo -e "${YELLOW}Architecture   :${RESET} $(uname -m)"
    echo -e "${YELLOW}Uptime         :${RESET} $(uptime -p 2>/dev/null || uptime)"
    echo -e "${YELLOW}Shell          :${RESET} $SHELL"
    echo -e "${YELLOW}Logged-in User :${RESET} $(whoami)"
    echo -e "${YELLOW}Session        :${RESET} $(tty)"
    pause
}

# -----------------------------------------------------------------------------
# 2. CPU INFORMATION
# -----------------------------------------------------------------------------
show_cpu_info() {
    print_section "CPU Information"
    if [[ -f /proc/cpuinfo ]]; then
        echo -e "${YELLOW}Model          :${RESET} $(grep 'model name' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)"
        echo -e "${YELLOW}Physical CPUs  :${RESET} $(grep 'physical id' /proc/cpuinfo | sort -u | wc -l)"
        echo -e "${YELLOW}Cores per CPU  :${RESET} $(grep 'cpu cores' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)"
        echo -e "${YELLOW}Logical CPUs   :${RESET} $(nproc)"
        echo -e "${YELLOW}CPU MHz        :${RESET} $(grep 'cpu MHz' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs) MHz"
        echo -e "${YELLOW}Cache Size     :${RESET} $(grep 'cache size' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs)"
    else
        sysctl -a 2>/dev/null | grep -E 'hw.model|hw.ncpu|hw.cpufrequency' | while read -r line; do
            echo -e "${YELLOW}${line}${RESET}"
        done
    fi
    echo -e "\n${YELLOW}Current Load   :${RESET} $(cat /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')"
    pause
}

# -----------------------------------------------------------------------------
# 3. MEMORY USAGE
# -----------------------------------------------------------------------------
show_memory_usage() {
    print_section "Memory Usage"
    if command -v free &>/dev/null; then
        free -h | awk '
        NR==1 { printf "%-15s %10s %10s %10s %10s\n", "", $1, $2, $3, $4 }
        NR==2 { printf "'"${YELLOW}"'%-15s'"${RESET}"' %10s %10s %10s %10s\n", "RAM:", $2, $3, $4, $7 }
        NR==3 { printf "'"${YELLOW}"'%-15s'"${RESET}"' %10s %10s %10s\n", "Swap:", $2, $3, $4 }
        '
    else
        print_warn "free command not found."
    fi

    echo ""
    TOTAL=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    AVAIL=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [[ -n "$TOTAL" && -n "$AVAIL" ]]; then
        USED=$(( TOTAL - AVAIL ))
        PCT=$(( USED * 100 / TOTAL ))
        BAR_FILLED=$(( PCT / 5 ))
        BAR_EMPTY=$(( 20 - BAR_FILLED ))
        BAR="${GREEN}"
        [[ $PCT -gt 70 ]] && BAR="${YELLOW}"
        [[ $PCT -gt 90 ]] && BAR="${RED}"
        printf "${YELLOW}Usage Bar      :${RESET} [${BAR}"
        printf '█%.0s' $(seq 1 $BAR_FILLED)
        printf "${RESET}"
        printf '░%.0s' $(seq 1 $BAR_EMPTY)
        printf "] %d%%\n" "$PCT"
    fi
    pause
}

# -----------------------------------------------------------------------------
# 4. DISK USAGE
# -----------------------------------------------------------------------------
show_disk_usage() {
    print_section "Disk Usage"
    df -h --output=source,fstype,size,used,avail,pcent,target 2>/dev/null \
        | grep -v tmpfs | grep -v devtmpfs | grep -v udev \
        | awk 'NR==1{printf "'"${CYAN}${BOLD}"'%-22s %-8s %6s %6s %6s %5s %-s\n'"${RESET}"'", $1,$2,$3,$4,$5,$6,$7}
               NR>1 {
                   pct=$6+0
                   color="'"${GREEN}"'"
                   if(pct>70) color="'"${YELLOW}"'"
                   if(pct>90) color="'"${RED}"'"
                   printf "%-22s %-8s %6s %6s %6s "color"%5s'"${RESET}"' %-s\n", $1,$2,$3,$4,$5,$6,$7
               }'
    pause
}

# -----------------------------------------------------------------------------
# 5. PROCESS LISTING
# -----------------------------------------------------------------------------
show_process_list() {
    print_section "Running Processes (Top 20 by PID)"
    ps aux --sort=pid 2>/dev/null | head -21 \
        | awk 'NR==1{printf "'"${CYAN}${BOLD}"'%-10s %-6s %-5s %-5s %-s\n'"${RESET}"'", "USER","PID","%CPU","%MEM","COMMAND"}
               NR>1{printf "%-10s %-6s %-5s %-5s %-s\n", $1,$2,$3,$4,$11}'
    pause
}

# -----------------------------------------------------------------------------
# 6. KILL PROCESS
# -----------------------------------------------------------------------------
kill_process() {
    print_section "Kill a Process"
    echo -n -e "${YELLOW}Enter PID or process name to kill: ${RESET}"
    read -r TARGET
    [[ -z "$TARGET" ]] && { print_error "No input provided."; pause; return; }

    if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
        if kill -0 "$TARGET" 2>/dev/null; then
            kill -9 "$TARGET" && print_success "Process $TARGET killed." || print_error "Failed to kill PID $TARGET."
        else
            print_error "PID $TARGET not found."
        fi
    else
        PIDS=$(pgrep -d',' -x "$TARGET" 2>/dev/null)
        if [[ -n "$PIDS" ]]; then
            pkill -9 -x "$TARGET" && print_success "Killed all '$TARGET' processes (PIDs: $PIDS)." || print_error "Failed."
        else
            print_error "No process named '$TARGET' found."
        fi
    fi
    pause
}

# -----------------------------------------------------------------------------
# 7. NETWORK INFORMATION
# -----------------------------------------------------------------------------
show_network_info() {
    print_section "Network Information"
    echo -e "${YELLOW}Interfaces:${RESET}"
    ip -brief address show 2>/dev/null || ifconfig 2>/dev/null | grep -E '^[a-z]|inet '
    echo ""
    echo -e "${YELLOW}Default Gateway:${RESET}"
    ip route show default 2>/dev/null || netstat -rn 2>/dev/null | grep "^0.0.0.0"
    echo ""
    echo -e "${YELLOW}DNS Servers:${RESET}"
    grep nameserver /etc/resolv.conf 2>/dev/null || print_warn "Cannot read /etc/resolv.conf"
    echo ""
    echo -e "${YELLOW}Public IP:${RESET}"
    curl -s --max-time 5 https://api.ipify.org 2>/dev/null && echo || print_warn "Could not reach external IP service."
    pause
}

# -----------------------------------------------------------------------------
# 8. PING HOST
# -----------------------------------------------------------------------------
ping_host() {
    print_section "Ping a Host"
    echo -n -e "${YELLOW}Enter hostname or IP to ping: ${RESET}"
    read -r HOST
    [[ -z "$HOST" ]] && { print_error "No host entered."; pause; return; }
    echo -n -e "${YELLOW}Number of packets (default 4): ${RESET}"
    read -r COUNT
    COUNT=${COUNT:-4}
    echo ""
    ping -c "$COUNT" "$HOST" && print_success "Ping to $HOST successful." || print_error "Ping to $HOST failed."
    pause
}

# -----------------------------------------------------------------------------
# 9. PORT CHECKER
# -----------------------------------------------------------------------------
check_port() {
    print_section "Port Checker"
    echo -n -e "${YELLOW}Enter hostname or IP: ${RESET}"
    read -r HOST
    echo -n -e "${YELLOW}Enter port number: ${RESET}"
    read -r PORT
    [[ -z "$HOST" || -z "$PORT" ]] && { print_error "Host and port are required."; pause; return; }

    if timeout 3 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
        print_success "Port $PORT on $HOST is OPEN."
    else
        print_error "Port $PORT on $HOST is CLOSED or unreachable."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 10. FILE SEARCH
# -----------------------------------------------------------------------------
file_search() {
    print_section "File Search"
    echo -n -e "${YELLOW}Search in directory (default: /): ${RESET}"
    read -r SEARCH_DIR
    SEARCH_DIR=${SEARCH_DIR:-/}
    echo -n -e "${YELLOW}Filename pattern (e.g. *.log): ${RESET}"
    read -r PATTERN
    [[ -z "$PATTERN" ]] && { print_error "Pattern required."; pause; return; }

    echo -e "\n${CYAN}Searching for '$PATTERN' in '$SEARCH_DIR'...${RESET}\n"
    find "$SEARCH_DIR" -name "$PATTERN" 2>/dev/null | head -50
    echo ""
    print_info "Showing up to 50 results."
    pause
}

# -----------------------------------------------------------------------------
# 11. DIRECTORY SIZE ANALYZER
# -----------------------------------------------------------------------------
dir_size_analyzer() {
    print_section "Directory Size Analyzer"
    echo -n -e "${YELLOW}Enter directory path (default: .): ${RESET}"
    read -r DIR_PATH
    DIR_PATH=${DIR_PATH:-.}
    [[ ! -d "$DIR_PATH" ]] && { print_error "Directory not found."; pause; return; }

    echo -e "\n${CYAN}Top 15 largest items in '$DIR_PATH':${RESET}\n"
    du -ah "$DIR_PATH" 2>/dev/null | sort -rh | head -15
    echo ""
    echo -e "${YELLOW}Total size:${RESET} $(du -sh "$DIR_PATH" 2>/dev/null | cut -f1)"
    pause
}

# -----------------------------------------------------------------------------
# 12. BACKUP DIRECTORY TO TAR.GZ
# -----------------------------------------------------------------------------
backup_directory() {
    print_section "Backup Directory to tar.gz"
    echo -n -e "${YELLOW}Source directory to backup: ${RESET}"
    read -r SRC
    [[ ! -d "$SRC" ]] && { print_error "Source directory not found."; pause; return; }
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BASENAME=$(basename "$SRC")
    DEST="${BASENAME}_backup_${TIMESTAMP}.tar.gz"
    echo -n -e "${YELLOW}Output file (default: $DEST): ${RESET}"
    read -r CUSTOM_DEST
    DEST=${CUSTOM_DEST:-$DEST}

    echo -e "\n${CYAN}Creating backup...${RESET}"
    tar -czf "$DEST" "$SRC" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        SIZE=$(du -sh "$DEST" | cut -f1)
        print_success "Backup created: $DEST ($SIZE)"
    else
        print_error "Backup failed."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 13. EXTRACT ARCHIVE
# -----------------------------------------------------------------------------
extract_archive() {
    print_section "Extract Archive"
    echo -n -e "${YELLOW}Enter archive file path: ${RESET}"
    read -r ARCHIVE
    [[ ! -f "$ARCHIVE" ]] && { print_error "File not found: $ARCHIVE"; pause; return; }
    echo -n -e "${YELLOW}Extract to directory (default: current): ${RESET}"
    read -r DEST_DIR
    DEST_DIR=${DEST_DIR:-.}
    mkdir -p "$DEST_DIR"

    case "$ARCHIVE" in
        *.tar.gz|*.tgz)  tar -xzf "$ARCHIVE" -C "$DEST_DIR" ;;
        *.tar.bz2|*.tbz) tar -xjf "$ARCHIVE" -C "$DEST_DIR" ;;
        *.tar.xz)         tar -xJf "$ARCHIVE" -C "$DEST_DIR" ;;
        *.tar)            tar -xf  "$ARCHIVE" -C "$DEST_DIR" ;;
        *.zip)            unzip -q  "$ARCHIVE" -d "$DEST_DIR" ;;
        *.gz)             gunzip -k "$ARCHIVE" ;;
        *.bz2)            bunzip2 -k "$ARCHIVE" ;;
        *.xz)             xz -dk   "$ARCHIVE" ;;
        *) print_error "Unsupported archive format."; pause; return ;;
    esac

    [[ $? -eq 0 ]] && print_success "Extracted to '$DEST_DIR'." || print_error "Extraction failed."
    pause
}

# -----------------------------------------------------------------------------
# 14. CALCULATOR
# -----------------------------------------------------------------------------
calculator() {
    print_section "Calculator (Basic & Scientific)"
    print_info "Supports: + - * / % ^ sqrt() sin() cos() log() etc."
    print_info "Type 'quit' to exit calculator.\n"

    while true; do
        echo -n -e "${YELLOW}calc> ${RESET}"
        read -r EXPR
        [[ "$EXPR" == "quit" || "$EXPR" == "q" ]] && break
        [[ -z "$EXPR" ]] && continue
        RESULT=$(echo "scale=6; $EXPR" | bc -l 2>/dev/null)
        if [[ $? -eq 0 && -n "$RESULT" ]]; then
            echo -e "${GREEN}= $RESULT${RESET}"
        else
            print_error "Invalid expression."
        fi
    done
    pause
}

# -----------------------------------------------------------------------------
# 15. USER INFORMATION
# -----------------------------------------------------------------------------
show_user_info() {
    print_section "User Information"
    echo -n -e "${YELLOW}Enter username (default: current user): ${RESET}"
    read -r UNAME
    UNAME=${UNAME:-$(whoami)}

    if id "$UNAME" &>/dev/null; then
        echo -e "${YELLOW}Username       :${RESET} $UNAME"
        echo -e "${YELLOW}UID            :${RESET} $(id -u "$UNAME")"
        echo -e "${YELLOW}GID            :${RESET} $(id -g "$UNAME")"
        echo -e "${YELLOW}Groups         :${RESET} $(id -Gn "$UNAME")"
        echo -e "${YELLOW}Home Directory :${RESET} $(getent passwd "$UNAME" | cut -d: -f6)"
        echo -e "${YELLOW}Default Shell  :${RESET} $(getent passwd "$UNAME" | cut -d: -f7)"
        echo -e "${YELLOW}Last Login     :${RESET} $(last "$UNAME" 2>/dev/null | head -1)"
    else
        print_error "User '$UNAME' not found."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 16. CHANGE FILE PERMISSIONS
# -----------------------------------------------------------------------------
change_permissions() {
    print_section "Change File Permissions"
    echo -n -e "${YELLOW}Enter file/directory path: ${RESET}"
    read -r FPATH
    [[ ! -e "$FPATH" ]] && { print_error "Path not found."; pause; return; }

    echo -e "${CYAN}Current permissions: $(stat -c '%A %U:%G' "$FPATH" 2>/dev/null || ls -ld "$FPATH")${RESET}"
    echo -n -e "${YELLOW}Enter new permissions (e.g. 755 or u+x): ${RESET}"
    read -r PERMS
    [[ -z "$PERMS" ]] && { print_error "No permissions entered."; pause; return; }

    chmod "$PERMS" "$FPATH" && print_success "Permissions changed to '$PERMS' on '$FPATH'." || print_error "Failed to change permissions."
    pause
}

# -----------------------------------------------------------------------------
# 17. SERVICE STATUS CHECKER
# -----------------------------------------------------------------------------
check_service_status() {
    print_section "Service Status Checker"
    echo -n -e "${YELLOW}Enter service name (e.g. nginx, ssh): ${RESET}"
    read -r SVC
    [[ -z "$SVC" ]] && { print_error "No service name entered."; pause; return; }

    if command -v systemctl &>/dev/null; then
        systemctl status "$SVC" --no-pager 2>/dev/null || print_error "Service '$SVC' not found or systemctl unavailable."
    else
        service "$SVC" status 2>/dev/null || print_error "Service '$SVC' not found."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 18. START SERVICE
# -----------------------------------------------------------------------------
start_service() {
    print_section "Start a Service"
    require_root || { pause; return; }
    echo -n -e "${YELLOW}Enter service name to start: ${RESET}"
    read -r SVC
    [[ -z "$SVC" ]] && { print_error "No service name entered."; pause; return; }

    if command -v systemctl &>/dev/null; then
        systemctl start "$SVC" && print_success "Service '$SVC' started." || print_error "Failed to start '$SVC'."
    else
        service "$SVC" start && print_success "Service '$SVC' started." || print_error "Failed to start '$SVC'."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 19. STOP SERVICE
# -----------------------------------------------------------------------------
stop_service() {
    print_section "Stop a Service"
    require_root || { pause; return; }
    echo -n -e "${YELLOW}Enter service name to stop: ${RESET}"
    read -r SVC
    [[ -z "$SVC" ]] && { print_error "No service name entered."; pause; return; }

    if command -v systemctl &>/dev/null; then
        systemctl stop "$SVC" && print_success "Service '$SVC' stopped." || print_error "Failed to stop '$SVC'."
    else
        service "$SVC" stop && print_success "Service '$SVC' stopped." || print_error "Failed to stop '$SVC'."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 20. DATABASE SERVICE CHECKER (PostgreSQL / ShaktiDB)
# -----------------------------------------------------------------------------
check_db_service() {
    print_section "Database Service Checker"

    echo -e "${CYAN}Checking PostgreSQL...${RESET}"
    if command -v pg_isready &>/dev/null; then
        pg_isready &>/dev/null && print_success "PostgreSQL is running." || print_warn "PostgreSQL is NOT running."
        pg_isready 2>&1 | head -2
    elif systemctl is-active --quiet postgresql 2>/dev/null; then
        print_success "PostgreSQL service is active."
    elif pgrep -x postgres &>/dev/null; then
        print_success "PostgreSQL process found (PID: $(pgrep -x postgres | head -1))."
    else
        print_warn "PostgreSQL does not appear to be running."
    fi

    echo ""
    echo -e "${CYAN}Checking ShaktiDB (port 5050)...${RESET}"
    if pgrep -x shaktidb &>/dev/null; then
        print_success "ShaktiDB process found."
    elif timeout 2 bash -c "echo >/dev/tcp/localhost/5050" 2>/dev/null; then
        print_success "ShaktiDB is listening on port 5050."
    else
        print_warn "ShaktiDB is NOT running or not on port 5050."
    fi

    echo ""
    echo -e "${CYAN}Checking MySQL/MariaDB...${RESET}"
    if mysqladmin ping -h localhost 2>/dev/null | grep -q alive; then
        print_success "MySQL/MariaDB is running."
    elif systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mariadb 2>/dev/null; then
        print_success "MySQL/MariaDB service is active."
    else
        print_warn "MySQL/MariaDB does not appear to be running."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 21. LOG VIEWER
# -----------------------------------------------------------------------------
view_logs() {
    print_section "Log Viewer"
    echo -e "  ${YELLOW}1)${RESET} /var/log/syslog"
    echo -e "  ${YELLOW}2)${RESET} /var/log/auth.log"
    echo -e "  ${YELLOW}3)${RESET} /var/log/dmesg"
    echo -e "  ${YELLOW}4)${RESET} /var/log/kern.log"
    echo -e "  ${YELLOW}5)${RESET} journalctl (last 50 lines)"
    echo -e "  ${YELLOW}6)${RESET} Custom log file"
    echo -n -e "\n${YELLOW}Choose log [1-6]: ${RESET}"
    read -r LOG_CHOICE

    case $LOG_CHOICE in
        1) LOGFILE="/var/log/syslog" ;;
        2) LOGFILE="/var/log/auth.log" ;;
        3) LOGFILE="/var/log/dmesg" ;;
        4) LOGFILE="/var/log/kern.log" ;;
        5) echo ""; journalctl -n 50 --no-pager 2>/dev/null || print_error "journalctl not available."; pause; return ;;
        6) echo -n -e "${YELLOW}Enter log file path: ${RESET}"; read -r LOGFILE ;;
        *) print_error "Invalid choice."; pause; return ;;
    esac

    if [[ -f "$LOGFILE" ]]; then
        echo -n -e "${YELLOW}Lines to display (default 30): ${RESET}"
        read -r LINES
        LINES=${LINES:-30}
        echo ""
        tail -n "$LINES" "$LOGFILE" 2>/dev/null | grep --color=auto -E 'error|warn|fail|crit|$' || cat "$LOGFILE" | tail -n "$LINES"
    else
        print_error "Log file not found: $LOGFILE"
    fi
    pause
}

# -----------------------------------------------------------------------------
# 22. SYSTEM UPDATE
# -----------------------------------------------------------------------------
system_update() {
    print_section "System Update"
    require_root || { pause; return; }
    print_warn "This will update your system packages."
    echo -n -e "${YELLOW}Proceed? [y/N]: ${RESET}"
    read -r CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { print_info "Update cancelled."; pause; return; }

    if command -v apt &>/dev/null; then
        print_info "Using apt..."
        apt update && apt upgrade -y
    elif command -v dnf &>/dev/null; then
        print_info "Using dnf..."
        dnf update -y
    elif command -v yum &>/dev/null; then
        print_info "Using yum..."
        yum update -y
    elif command -v pacman &>/dev/null; then
        print_info "Using pacman..."
        pacman -Syu --noconfirm
    else
        print_error "No supported package manager found."
    fi

    [[ $? -eq 0 ]] && print_success "System updated successfully." || print_error "Update encountered errors."
    pause
}

# -----------------------------------------------------------------------------
# 23. TOP MEMORY-CONSUMING PROCESSES
# -----------------------------------------------------------------------------
top_memory_processes() {
    print_section "Top 10 Memory-Consuming Processes"
    printf "${CYAN}${BOLD}%-8s %-15s %-8s %-8s %-s\n${RESET}" "PID" "USER" "%MEM" "RSS(MB)" "COMMAND"
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11 {
        rss_mb = $6 / 1024
        printf "%-8s %-15s %-8s %-8.1f %-s\n", $2, $1, $4, rss_mb, $11
    }'
    pause
}

# -----------------------------------------------------------------------------
# 24. TOP CPU-CONSUMING PROCESSES
# -----------------------------------------------------------------------------
top_cpu_processes() {
    print_section "Top 10 CPU-Consuming Processes"
    printf "${CYAN}${BOLD}%-8s %-15s %-8s %-8s %-s\n${RESET}" "PID" "USER" "%CPU" "%MEM" "COMMAND"
    ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=11 {
        printf "%-8s %-15s %-8s %-8s %-s\n", $2, $1, $3, $4, $11
    }'
    pause
}

# -----------------------------------------------------------------------------
# 25. DATE/TIME DISPLAY
# -----------------------------------------------------------------------------
show_datetime() {
    print_section "Date & Time"
    echo -e "${YELLOW}Local Date/Time  :${RESET} $(date '+%A, %B %d, %Y %I:%M:%S %p %Z')"
    echo -e "${YELLOW}UTC Date/Time    :${RESET} $(date -u '+%A, %B %d, %Y %I:%M:%S %p UTC')"
    echo -e "${YELLOW}Unix Timestamp   :${RESET} $(date +%s)"
    echo -e "${YELLOW}Week Number      :${RESET} Week $(date +%V) of $(date +%Y)"
    echo -e "${YELLOW}Day of Year      :${RESET} Day $(date +%j) of $(date +%Y)"
    echo -e "${YELLOW}Timezone         :${RESET} $(timedatectl show -p Timezone --value 2>/dev/null || date +%Z)"
    pause
}

# -----------------------------------------------------------------------------
# 26. CHANGE HOSTNAME
# -----------------------------------------------------------------------------
change_hostname() {
    print_section "Change Hostname"
    require_root || { pause; return; }
    echo -e "${YELLOW}Current hostname :${RESET} $(hostname)"
    echo -n -e "${YELLOW}Enter new hostname: ${RESET}"
    read -r NEW_HOST
    [[ -z "$NEW_HOST" ]] && { print_error "Hostname cannot be empty."; pause; return; }

    if command -v hostnamectl &>/dev/null; then
        hostnamectl set-hostname "$NEW_HOST" && print_success "Hostname changed to '$NEW_HOST'. (Relogin or reboot to fully apply)" || print_error "Failed to change hostname."
    else
        echo "$NEW_HOST" > /etc/hostname
        hostname "$NEW_HOST"
        print_success "Hostname set to '$NEW_HOST'."
    fi
    pause
}

# -----------------------------------------------------------------------------
# 27. CREATE USER
# -----------------------------------------------------------------------------
create_user() {
    print_section "Create New User"
    require_root || { pause; return; }
    echo -n -e "${YELLOW}Enter new username: ${RESET}"
    read -r NEW_USER
    [[ -z "$NEW_USER" ]] && { print_error "Username cannot be empty."; pause; return; }

    if id "$NEW_USER" &>/dev/null; then
        print_warn "User '$NEW_USER' already exists."
    else
        echo -n -e "${YELLOW}Create home directory? [Y/n]: ${RESET}"
        read -r MKHOME
        if [[ "$MKHOME" == "n" || "$MKHOME" == "N" ]]; then
            useradd "$NEW_USER" && print_success "User '$NEW_USER' created (no home directory)."
        else
            useradd -m "$NEW_USER" && print_success "User '$NEW_USER' created with home directory."
        fi

        if [[ $? -eq 0 ]]; then
            echo -n -e "${YELLOW}Set password for '$NEW_USER'? [Y/n]: ${RESET}"
            read -r SETPW
            [[ "$SETPW" != "n" && "$SETPW" != "N" ]] && passwd "$NEW_USER"
        fi
    fi
    pause
}

# -----------------------------------------------------------------------------
# 28. DELETE USER
# -----------------------------------------------------------------------------
delete_user() {
    print_section "Delete User"
    require_root || { pause; return; }
    echo -n -e "${YELLOW}Enter username to delete: ${RESET}"
    read -r DEL_USER
    [[ -z "$DEL_USER" ]] && { print_error "No username entered."; pause; return; }

    if ! id "$DEL_USER" &>/dev/null; then
        print_error "User '$DEL_USER' does not exist."
    else
        print_warn "This will delete user '$DEL_USER'!"
        echo -n -e "${YELLOW}Also remove home directory? [y/N]: ${RESET}"
        read -r RMHOME
        echo -n -e "${RED}Confirm deletion of '$DEL_USER' [yes/NO]: ${RESET}"
        read -r CONFIRM
        if [[ "$CONFIRM" == "yes" ]]; then
            if [[ "$RMHOME" == "y" || "$RMHOME" == "Y" ]]; then
                userdel -r "$DEL_USER" && print_success "User '$DEL_USER' and home directory deleted."
            else
                userdel "$DEL_USER" && print_success "User '$DEL_USER' deleted (home directory kept)."
            fi
            [[ $? -ne 0 ]] && print_error "Failed to delete user '$DEL_USER'."
        else
            print_info "Deletion cancelled."
        fi
    fi
    pause
}

# -----------------------------------------------------------------------------
# MAIN MENU
# -----------------------------------------------------------------------------
show_menu() {
    print_header
    echo -e "  ${BOLD}${WHITE}SYSTEM${RESET}                          ${BOLD}${WHITE}NETWORK${RESET}"
    echo -e "  ${GREEN} 1)${RESET} System Information         ${GREEN}  7)${RESET} Network Info"
    echo -e "  ${GREEN} 2)${RESET} CPU Information            ${GREEN}  8)${RESET} Ping Host"
    echo -e "  ${GREEN} 3)${RESET} Memory Usage               ${GREEN}  9)${RESET} Port Checker"
    echo -e "  ${GREEN} 4)${RESET} Disk Usage"
    echo -e "  ${GREEN} 5)${RESET} Process Listing            ${BOLD}${WHITE}FILES & ARCHIVES${RESET}"
    echo -e "  ${GREEN} 6)${RESET} Kill Process               ${GREEN}10)${RESET} File Search"
    echo -e "                                 ${GREEN}11)${RESET} Directory Size Analyzer"
    echo -e "  ${BOLD}${WHITE}SERVICES & DATABASE${RESET}            ${GREEN}12)${RESET} Backup Directory to tar.gz"
    echo -e "  ${GREEN}17)${RESET} Service Status             ${GREEN}13)${RESET} Extract Archive"
    echo -e "  ${GREEN}18)${RESET} Start Service"
    echo -e "  ${GREEN}19)${RESET} Stop Service               ${BOLD}${WHITE}ADMIN${RESET}"
    echo -e "  ${GREEN}20)${RESET} Database Service Checker   ${GREEN}27)${RESET} Create User"
    echo -e "  ${GREEN}21)${RESET} Log Viewer                 ${GREEN}28)${RESET} Delete User"
    echo -e "  ${GREEN}22)${RESET} System Update              ${GREEN}26)${RESET} Change Hostname"
    echo -e "                                 ${GREEN}16)${RESET} Change File Permissions"
    echo -e "  ${BOLD}${WHITE}ANALYTICS${RESET}                       ${GREEN}15)${RESET} User Information"
    echo -e "  ${GREEN}23)${RESET} Top Memory Processes"
    echo -e "  ${GREEN}24)${RESET} Top CPU Processes          ${BOLD}${WHITE}UTILITIES${RESET}"
    echo -e "  ${GREEN}25)${RESET} Date/Time Display          ${GREEN}14)${RESET} Calculator"
    echo -e "                                 ${RED}29)${RESET} Exit"
    echo ""
    echo -e "${DIM}────────────────────────────────────────────${RESET}"
    echo -n -e "  ${YELLOW}${BOLD}Enter choice [1-29]: ${RESET}"
}

# -----------------------------------------------------------------------------
# MAIN LOOP
# -----------------------------------------------------------------------------
main() {
    while true; do
        show_menu
        read -r CHOICE

        case $CHOICE in
            1)  show_system_info ;;
            2)  show_cpu_info ;;
            3)  show_memory_usage ;;
            4)  show_disk_usage ;;
            5)  show_process_list ;;
            6)  kill_process ;;
            7)  show_network_info ;;
            8)  ping_host ;;
            9)  check_port ;;
            10) file_search ;;
            11) dir_size_analyzer ;;
            12) backup_directory ;;
            13) extract_archive ;;
            14) calculator ;;
            15) show_user_info ;;
            16) change_permissions ;;
            17) check_service_status ;;
            18) start_service ;;
            19) stop_service ;;
            20) check_db_service ;;
            21) view_logs ;;
            22) system_update ;;
            23) top_memory_processes ;;
            24) top_cpu_processes ;;
            25) show_datetime ;;
            26) change_hostname ;;
            27) create_user ;;
            28) delete_user ;;
            29|q|quit|exit)
                echo -e "\n${GREEN}${BOLD}Goodbye! Stay productive. 👋${RESET}\n"
                exit 0
                ;;
            *)
                print_error "Invalid option '$CHOICE'. Please choose 1-29."
                sleep 1
                ;;
        esac
    done
}

# Entry point
main
