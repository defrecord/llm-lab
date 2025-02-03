#!/bin/bash

# Base directory for data
DATA_DIR="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/data"
IMAGE_DIR="$DATA_DIR/images/jwalsh_"
LOG_DIR="$DATA_DIR/logs"

mkdir -p "$IMAGE_DIR"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/download_$(date +%Y%m%d_%H%M%S).log"
TOTAL_PAGES=1
FORCE_DOWNLOAD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_DOWNLOAD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Starting image download process at $(date)" | tee -a "$LOG_FILE"
echo "Target: $TOTAL_PAGES pages of images" | tee -a "$LOG_FILE"
if [ "$FORCE_DOWNLOAD" = true ]; then
    echo "Force download enabled for first page" | tee -a "$LOG_FILE"
fi

image_count=0
failed_count=0

# Fetch images from pages
for page in $(seq 1 $TOTAL_PAGES); do
    images_txt="$IMAGE_DIR/images_page${page}.txt"

    echo "Processing page $page of $TOTAL_PAGES..." | tee -a "$LOG_FILE"

    # Force redownload of first page if --force flag is set
    if [ "$FORCE_DOWNLOAD" = true ] && [ $page -eq 1 ]; then
        echo "Force downloading page 1..." | tee -a "$LOG_FILE"
        rm -f "$images_txt"
    fi

    if [ ! -f "$images_txt" ]; then
        echo "Fetching URLs from page $page..." | tee -a "$LOG_FILE"
        curl -s "https://flickr.com/photos/jwalsh_/page$page" | \
        grep -o 'src="//live.staticflickr.com[^"]*"' | \
        cut -d'"' -f2 | \
        sed 's/^/https:/' > "$images_txt"

        # Check if we got any URLs
        if [ ! -s "$images_txt" ]; then
            echo "Warning: No images found on page $page" | tee -a "$LOG_FILE"
            continue
        fi
    fi

    # Download images from this page
    while read -r image; do
        filename=$(basename "$image")
        dest_path="$IMAGE_DIR/$filename"

        # Function to download and verify file
        download_and_verify() {
            if wget -q -O "$dest_path" "$image"; then
                # Check if file exists and is not empty
                if [ -s "$dest_path" ]; then
                    ((image_count++))
                    echo "Successfully downloaded: $filename (Total: $image_count)" | tee -a "$LOG_FILE"
                    return 0
                else
                    echo "Warning: Downloaded file is empty: $filename" | tee -a "$LOG_FILE"
                    rm -f "$dest_path"
                    return 1
                fi
            else
                echo "Failed to download: $image" | tee -a "$LOG_FILE"
                rm -f "$dest_path"
                return 1
            fi
        }

        # Force redownload of first page images if --force flag is set
        if [ "$FORCE_DOWNLOAD" = true ] && [ $page -eq 1 ]; then
            if [ -f "$dest_path" ]; then
                rm -f "$dest_path"
                echo "Force removing existing file: $filename" | tee -a "$LOG_FILE"
            fi
        fi

        # Check if file exists and is empty
        if [ -f "$dest_path" ] && [ ! -s "$dest_path" ]; then
            echo "Found empty file, removing and retrying: $filename" | tee -a "$LOG_FILE"
            rm -f "$dest_path"
        fi

        # If file doesn't exist or was empty, try to download
        if [ ! -f "$dest_path" ]; then
            # Try downloading up to 3 times
            max_attempts=3
            attempt=1
            while [ $attempt -le $max_attempts ]; do
                echo "Download attempt $attempt of $max_attempts for $filename" | tee -a "$LOG_FILE"
                if download_and_verify; then
                    break
                fi
                ((attempt++))
                if [ $attempt -le $max_attempts ]; then
                    sleep 2  # Wait before retry
                fi
            done

            if [ $attempt -gt $max_attempts ]; then
                ((failed_count++))
                echo "Failed all download attempts for: $filename" | tee -a "$LOG_FILE"
            fi
        else 
            echo "Skipping existing: $dest_path" | tee -a "$LOG_FILE"
        fi
    done < "$images_txt"

    # Progress report
    echo "Page $page complete. Current totals:" | tee -a "$LOG_FILE"
    echo "- Successfully downloaded: $image_count" | tee -a "$LOG_FILE"
    echo "- Failed downloads: $failed_count" | tee -a "$LOG_FILE"
done

echo "Download process complete at $(date)" | tee -a "$LOG_FILE"
echo "Final statistics:" | tee -a "$LOG_FILE"
echo "- Total images downloaded: $image_count" | tee -a "$LOG_FILE"
echo "- Total failed downloads: $failed_count" | tee -a "$LOG_FILE"
