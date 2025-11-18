#!/bin/bash

############################################################
#  Service Monitor Script (Linux - Bash)
#  Del 2 – Bash (Linux) til server-automatisering
#
#  Dette script:
#   1. Henter alle aktive systemd-services
#   2. Finder deres MainPID
#   3. Henter CPU og RAM for hver proces via ps
#   4. Sorterer resultater efter ressourceforbrug
#   5. Gemmer resultat i en logfil i brugerens hjemmemappe
#   6. Viser et pænt output i terminalen
#
#  Kræver:
#    systemctl, awk, ps
############################################################

echo "=== Henter aktive systemd-services ==="

# -----------------------------------------------------------
# 1. Hent alle aktive services via systemctl
#    Format: SERVICE | LOAD | ACTIVE | SUB | DESCRIPTION
# -----------------------------------------------------------
services=$(systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{print $1}')

# Resultat-array
declare -a results

# -----------------------------------------------------------
# 2+3. Loop gennem services, find PID, CPU og RAM via ps
# -----------------------------------------------------------
for svc in $services; do

    # Hent MainPID (proces-id) fra systemctl show
    pid=$(systemctl show "$svc" -p MainPID --value)

    # Hvis PID = 0, betyder det ingen proces aktiv → skip
    if [[ "$pid" -eq 0 ]]; then
        continue
    fi

    # Hent CPU (%) og RAM (%) via ps
    cpu=$(ps -p "$pid" -o %cpu= | awk '{print $1}')
    mem=$(ps -p "$pid" -o %mem= | awk '{print $1}')

    # Hvis ps ikke finder noget, skip
    if [[ -z "$cpu" || -z "$mem" ]]; then
        continue
    fi

    # Tilføj til array som: cpu mem pid serviceName
    results+=("$cpu $mem $pid $svc")

done

# -----------------------------------------------------------
# 4. Sorter efter CPU, derefter RAM
# -----------------------------------------------------------
sorted=$(printf "%s\n" "${results[@]}" | sort -k1 -nr -k2 -nr)

# -----------------------------------------------------------
# 5. Gem til logfil med timestamp
# -----------------------------------------------------------
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="$HOME/service_monitor_$timestamp.log"

printf "%s\n" "${sorted[@]}" > "$logfile"

echo "Log gemt i: $logfile"
echo ""

# -----------------------------------------------------------
# 6. Vis resultat som en pæn tabel
# -----------------------------------------------------------
echo "=== Aktive systemd-services sorteret efter ressourceforbrug ==="
echo "CPU%   MEM%   PID     SERVICE"
echo "-------------------------------------------"
printf "%s\n" "${sorted[@]}" | awk '{printf "%-6s %-6s %-7s %s\n", $1, $2, $3, $4}'
