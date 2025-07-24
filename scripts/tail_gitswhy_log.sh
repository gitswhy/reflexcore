#!/bin/bash
# Helper script to tail the Gitswhy events log in real time
LOG_FILE="$HOME/.gitswhy/events.log"
echo "Tailing $LOG_FILE (Ctrl+C to stop)"
tail -f "$LOG_FILE" 