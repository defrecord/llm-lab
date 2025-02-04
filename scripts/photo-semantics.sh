#!/bin/bash
set -euo pipefail

# Configuration
DATA_DIR="${DATA_DIR:-data}"
PHOTOS_DIR="${DATA_DIR}/images/jwalsh_"
OUTPUT_DIR="${DATA_DIR}/semantic-photos"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR"

# Map Flickr filenames to semantic names
declare -A PHOTOS=(
    ["54294349043_4f7443711a_c.jpg"]="pasta_with_greens.jpg"
    ["54303961908_08a034a911_z.jpg"]="urban_waterfront.jpg"
    ["54299583534_79863a9a4d_z.jpg"]="coffee_and_book.jpg"
    ["54294575492_226eb3407d_z.jpg"]="noodle_stir_fry.jpg"
    ["54295887205_266546a77e_z.jpg"]="sushi_platter.jpg"
    ["54298474192_24f36631de_z.jpg"]="documentation_page.jpg"
    ["54303950834_5c2edd7b63_z.jpg"]="colorful_interface.jpg"
)

# Function to clean and link photos
link_photos() {
    echo "Creating semantic links for photos..."
    for src in "${!PHOTOS[@]}"; do
        if [ -f "${PHOTOS_DIR}/${src}" ]; then
            dst="${PHOTOS[@][$src]}"
            echo "Linking ${src} → ${dst}"
            ln -f "${PHOTOS_DIR}/${src}" "${OUTPUT_DIR}/${dst}"
        else
            echo "Warning: Source photo not found: ${src}"
        fi
    done
}

# Create embeddings collection
create_embeddings() {
    echo "Creating embeddings collection..."
    llm sentence-transformers register all-MiniLM-L6-v2
    llm embed-multi photo-semantics \
        --model sentence-transformers/all-MiniLM-L6-v2 \
        --files "${OUTPUT_DIR}/*.jpg" \
        --store
}

# Test semantic searches
test_searches() {
    echo "Testing semantic searches..."
    
    # Test known categories
    for query in \
        "pasta or noodle dishes with sauce" \
        "coffee cups and cafe settings" \
        "urban skyline views near water" \
        "technical documentation and UI"; do
        echo -e "\nSearching for: $query"
        llm similar photo-semantics -c "$query"
    done

    # Test negative cases
    echo -e "\nTesting negative cases..."
    for query in \
        "portraits or people" \
        "cars and vehicles" \
        "pets and animals"; do
        echo -e "\nSearching for: $query (should find few/none)"
        llm similar photo-semantics -c "$query"
    done
}

# Main execution
main() {
    echo "Starting photo semantics demo..."
    link_photos
    create_embeddings
    test_searches
    echo "Demo complete. Results in ${OUTPUT_DIR}"
}

main "$@"