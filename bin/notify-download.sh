#!/bin/bash
set -eu

URL="$1"
DEST_PATH="$2"
CLEAN_NAME=$(basename "$DEST_PATH")

# 1. Initialize the Mako notification
notify-send -a "Download" -h string:x-canonical-private-synchronous:download -h int:value:0 "Downloading" "$CLEAN_NAME"

# 2. Start the download with progress piped to Mako
# We use PIPESTATUS array to check the exit code of curl (index 0)
curl -L --progress-bar -o "$DEST_PATH" "$URL" 2>&1 | \
stdbuf -oL tr '\r' '\n' | \
sed -un 's/.* \([0-9]\{1,3\}\)\.[0-9]%.*/\1/p' | \
while read -r progress; do
    notify-send -a "Download" \
                -h string:x-canonical-private-synchronous:download \
                -h int:value:"$progress" \
                "Downloading" "$progress% completed."
done

# 3. Handle success or failure based on curl's exit status
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
    # Update the notification to 100% and a final message
    notify-send -a "Download" -h string:x-canonical-private-synchronous:download -h int:value:100 "Download Complete" "$CLEAN_NAME"
    exit 0 # Success
else
    # Update notification to critical error
    notify-send -a "Download" -u critical -h string:x-canonical-private-synchronous:download "Download Failed" "Please check your internet connection."
    rm -f "$DEST_PATH" # Clean up the partially downloaded file
    exit 1 # Failure
fi
