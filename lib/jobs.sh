#!/bin/bash
# ZestSync - Job Management Library

JOBS_DIR="$CONFIG_DIR/jobs"
LOGS_DIR="$CONFIG_DIR/logs"

init_jobs() {
    mkdir -p "$JOBS_DIR"
    mkdir -p "$LOGS_DIR"
}

# Generate a slug from a name
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

# List all jobs
list_jobs() {
    local jobs=()
    for job_file in "$JOBS_DIR"/*.conf; do
        [[ -f "$job_file" ]] && jobs+=("$job_file")
    done
    echo "${jobs[@]}"
}

# Get job count
job_count() {
    local count=0
    for job_file in "$JOBS_DIR"/*.conf; do
        [[ -f "$job_file" ]] && ((count++))
    done
    echo $count
}

# Load a job config
load_job() {
    local job_file="$1"
    if [[ -f "$job_file" ]]; then
        source "$job_file"
        return 0
    fi
    return 1
}

# Save a job config
save_job() {
    local slug="$1"
    local name="$2"
    local source="$3"
    local dest="$4"
    local frequency="$5"
    local day="$6"
    local time="$7"
    local excludes="$8"
    local enabled="${9:-true}"
    
    local job_file="$JOBS_DIR/${slug}.conf"
    
    cat > "$job_file" << EOF
# ZestSync Job Configuration
NAME="$name"
SOURCE="$source"
DEST="$dest"
FREQUENCY="$frequency"
DAY="$day"
TIME="$time"
EXCLUDES="$excludes"
ENABLED="$enabled"
LAST_RUN=""
EOF
    
    echo "$job_file"
}

# Delete a job
delete_job() {
    local job_file="$1"
    local slug=$(basename "$job_file" .conf)
    
    # Remove job file
    rm -f "$job_file"
    
    # Remove associated launchd plist
    local plist="$HOME/Library/LaunchAgents/com.zestsync.${slug}.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null
        rm -f "$plist"
    fi
    
    # Remove log
    rm -f "$LOGS_DIR/${slug}.log"
}

# Update last run timestamp
update_last_run() {
    local job_file="$1"
    local timestamp=$(date +%s)
    
    if [[ -f "$job_file" ]]; then
        sed -i '' "s/^LAST_RUN=.*/LAST_RUN=\"$timestamp\"/" "$job_file"
    fi
}

# Check if job needs to run
job_needs_run() {
    local job_file="$1"
    local frequency="$2"
    local last_run="$3"
    
    [[ -z "$last_run" ]] && return 0
    
    local now=$(date +%s)
    local diff=$(( (now - last_run) / 86400 ))
    
    case "$frequency" in
        daily)   [[ $diff -ge 1 ]] && return 0 ;;
        weekly)  [[ $diff -ge 7 ]] && return 0 ;;
        monthly) [[ $diff -ge 30 ]] && return 0 ;;
    esac
    
    return 1
}

# Run a backup job
run_job() {
    local job_file="$1"
    local show_progress="${2:-true}"
    
    # Load job config
    source "$job_file"
    local slug=$(basename "$job_file" .conf)
    local log_file="$LOGS_DIR/${slug}.log"
    
    # Build exclude arguments
    local exclude_args=()
    for item in $EXCLUDES; do
        exclude_args+=(--exclude "$item")
    done
    
    # Always exclude common junk
    exclude_args+=(--exclude '.DS_Store')
    
    # Ensure destination exists
    mkdir -p "$DEST"
    
    # Log start
    echo "=== Backup started: $(date) ===" >> "$log_file"
    echo "Source: $SOURCE" >> "$log_file"
    echo "Dest: $DEST" >> "$log_file"
    
    if [[ "$show_progress" == "true" ]]; then
        # Run with live output
        rsync -avi --delete "${exclude_args[@]}" "${SOURCE}/" "$DEST/" 2>&1 | while IFS= read -r line; do
            echo "$line" >> "$log_file"
            
            # Show files being transferred
            if [[ "$line" =~ ^\>f ]]; then
                local file=$(echo "$line" | sed 's/^[^ ]* //')
                if [[ ${#file} -gt 50 ]]; then
                    file="...${file: -47}"
                fi
                printf "\r  ${GREEN}↑${NC} %-55s" "$file"
            elif [[ "$line" =~ ^\*deleting ]]; then
                local file=$(echo "$line" | sed 's/^\*deleting //')
                printf "\r  ${RED}✕${NC} %-55s" "$file"
            fi
        done
        echo ""
    else
        # Quiet mode
        rsync -av --delete "${exclude_args[@]}" "${SOURCE}/" "$DEST/" >> "$log_file" 2>&1
    fi
    
    # Log end
    echo "=== Backup completed: $(date) ===" >> "$log_file"
    echo "" >> "$log_file"
    
    # Update last run
    update_last_run "$job_file"
    
    return 0
}

# Get human-readable schedule
format_schedule() {
    local frequency="$1"
    local day="$2"
    local time="$3"
    
    case "$frequency" in
        daily)   echo "Daily at $time" ;;
        weekly)  echo "Every ${day^} at $time" ;;
        monthly) echo "Monthly on day $day at $time" ;;
        *)       echo "$frequency" ;;
    esac
}

# Get human-readable last run
format_last_run() {
    local last_run="$1"
    
    if [[ -z "$last_run" ]]; then
        echo "Never"
        return
    fi
    
    local now=$(date +%s)
    local diff=$(( now - last_run ))
    
    if [[ $diff -lt 60 ]]; then
        echo "Just now"
    elif [[ $diff -lt 3600 ]]; then
        echo "$((diff / 60)) minutes ago"
    elif [[ $diff -lt 86400 ]]; then
        echo "$((diff / 3600)) hours ago"
    else
        echo "$((diff / 86400)) days ago"
    fi
}

# Validate paths
validate_source() {
    local path="$1"
    [[ -d "$path" ]]
}

validate_dest() {
    local path="$1"
    # Destination can be created, just check parent exists
    local parent=$(dirname "$path")
    [[ -d "$parent" ]] || mkdir -p "$parent" 2>/dev/null
}
