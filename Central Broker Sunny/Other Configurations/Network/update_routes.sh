#!/bin/bash

# Define known MAC addresses (multiple per device allowed)
declare -A DEVICE_MACS=(
    ["cookie"]="dc:a6:32:ea:3d:43,6c:5a:b0:4a:90:32"
    ["cake"]="dc:a6:32:ea:3d:54,14:eb:b6:94:8f:a4"
)

# Define remote (behind-device) subnets
declare -A DEVICE_REMOTE_SUBNET=(
    ["cookie"]="192.168.153.0/24"
    ["cake"]="192.168.154.0/24"
)

# Define scanning interfaces and their subnets
declare -A IFACE_TO_SCAN=(
    ["wlx7cc2c60a6366"]="192.168.151.0/24"
    ["wlxa86e84a14458"]="192.168.152.0/24"
)

LOG_FILE="/tmp/route.log"

log() {
    echo "[$(date)] $1" | sudo tee -a "$LOG_FILE"
}

log "🔄 Starting dynamic route discovery..."

for iface in "${!IFACE_TO_SCAN[@]}"; do
    scan_subnet="${IFACE_TO_SCAN[$iface]}"
    log "🔍 Scanning $scan_subnet on $iface..."

    sudo nmap -sn "$scan_subnet" -n --send-ip -e "$iface" -oG - | awk '/Up$/{print $2}' | while read -r ip; do
        mac=$(arp -n "$ip" | awk '/ether/ {print $3}' | tr '[:upper:]' '[:lower:]')

        found=0
        for device in "${!DEVICE_MACS[@]}"; do
            IFS=',' read -ra mac_list <<< "${DEVICE_MACS[$device]}"
            for known_mac in "${mac_list[@]}"; do
                if [[ "$mac" == "$known_mac" ]]; then
                    remote_subnet="${DEVICE_REMOTE_SUBNET[$device]}"
                    log "✅ Found $device [$mac] at $ip. Adding route to $remote_subnet via $ip on $iface..."

                    if ip route | grep -q "$remote_subnet"; then
                        log "⚠️  Route to $remote_subnet already exists. Skipping..."
                    else
                        sudo ip route add "$remote_subnet" via "$ip" dev "$iface" && log "🚀 Route added: $remote_subnet via $ip on $iface"
                    fi
                    found=1
                    break 2  # Exit both loops
                fi
            done
        done

        if [[ "$found" -eq 0 ]]; then
            log "❌ MAC not found in mapping for $ip ($mac)"
        fi
    done
done

log "✅ Dynamic route discovery completed."
