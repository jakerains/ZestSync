#!/bin/bash
# ZestSync - Scheduler Library (launchd integration)

LAUNCHD_DIR="$HOME/Library/LaunchAgents"

# Convert day name to weekday number
day_to_number() {
    local day="$1"
    case "${day,,}" in
        sunday|sun)    echo 0 ;;
        monday|mon)    echo 1 ;;
        tuesday|tue)   echo 2 ;;
        wednesday|wed) echo 3 ;;
        thursday|thu)  echo 4 ;;
        friday|fri)    echo 5 ;;
        saturday|sat)  echo 6 ;;
        *)             echo 1 ;;  # Default to Monday
    esac
}

# Parse time string to hour and minute
parse_time() {
    local time="$1"
    local hour=$(echo "$time" | cut -d: -f1 | sed 's/^0//')
    local minute=$(echo "$time" | cut -d: -f2 | sed 's/^0//')
    echo "$hour $minute"
}

# Generate launchd plist for a job
generate_plist() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    
    # Load job config
    source "$job_file"
    
    local plist_file="$LAUNCHD_DIR/com.zestsync.${slug}.plist"
    local time_parts=($(parse_time "$TIME"))
    local hour="${time_parts[0]}"
    local minute="${time_parts[1]}"
    
    # Start building plist
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zestsync.${slug}</string>

    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/zestsync</string>
        <string>--run</string>
        <string>$slug</string>
        <string>--quiet</string>
    </array>

    <key>StartCalendarInterval</key>
EOF

    # Add schedule based on frequency
    case "$FREQUENCY" in
        daily)
            cat >> "$plist_file" << EOF
    <dict>
        <key>Hour</key>
        <integer>$hour</integer>
        <key>Minute</key>
        <integer>$minute</integer>
    </dict>
EOF
            ;;
        weekly)
            local weekday=$(day_to_number "$DAY")
            cat >> "$plist_file" << EOF
    <dict>
        <key>Weekday</key>
        <integer>$weekday</integer>
        <key>Hour</key>
        <integer>$hour</integer>
        <key>Minute</key>
        <integer>$minute</integer>
    </dict>
EOF
            ;;
        monthly)
            cat >> "$plist_file" << EOF
    <dict>
        <key>Day</key>
        <integer>$DAY</integer>
        <key>Hour</key>
        <integer>$hour</integer>
        <key>Minute</key>
        <integer>$minute</integer>
    </dict>
EOF
            ;;
    esac

    # Add remaining plist content
    cat >> "$plist_file" << EOF

    <!-- Run on login to catch missed backups -->
    <key>RunAtLoad</key>
    <true/>

    <!-- Low priority - won't slow down your Mac -->
    <key>LowPriorityIO</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>

    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/logs/${slug}-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/logs/${slug}-stderr.log</string>
</dict>
</plist>
EOF

    echo "$plist_file"
}

# Load a job's scheduler
load_scheduler() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    local plist_file="$LAUNCHD_DIR/com.zestsync.${slug}.plist"
    
    if [[ -f "$plist_file" ]]; then
        launchctl load "$plist_file" 2>/dev/null
        return $?
    fi
    return 1
}

# Unload a job's scheduler
unload_scheduler() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    local plist_file="$LAUNCHD_DIR/com.zestsync.${slug}.plist"
    
    if [[ -f "$plist_file" ]]; then
        launchctl unload "$plist_file" 2>/dev/null
        return $?
    fi
    return 1
}

# Reload scheduler (unload + regenerate + load)
reload_scheduler() {
    local job_file="$1"
    
    unload_scheduler "$job_file"
    generate_plist "$job_file"
    load_scheduler "$job_file"
}

# Check if scheduler is loaded
scheduler_is_loaded() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    
    launchctl list | grep -q "com.zestsync.${slug}"
}

# Enable scheduling for a job
enable_job() {
    local job_file="$1"
    
    # Update config
    sed -i '' 's/^ENABLED=.*/ENABLED="true"/' "$job_file"
    
    # Generate and load plist
    generate_plist "$job_file"
    load_scheduler "$job_file"
}

# Disable scheduling for a job
disable_job() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    local plist_file="$LAUNCHD_DIR/com.zestsync.${slug}.plist"
    
    # Update config
    sed -i '' 's/^ENABLED=.*/ENABLED="false"/' "$job_file"
    
    # Unload and remove plist
    unload_scheduler "$job_file"
    rm -f "$plist_file"
}

# Reload all job schedulers
reload_all_schedulers() {
    for job_file in "$JOBS_DIR"/*.conf; do
        [[ -f "$job_file" ]] || continue
        source "$job_file"
        
        if [[ "$ENABLED" == "true" ]]; then
            reload_scheduler "$job_file"
        fi
    done
}
