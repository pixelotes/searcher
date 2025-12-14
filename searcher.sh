#!/bin/bash

# --- Recursive Text Search Tool ---

display_help() {
    echo "Recursively finds text in files within a specified directory."
    echo ""
    echo "Usage: $0 [OPTIONS] -s <text_to_find> [-s <more_text> ...] <directory>"
    echo ""
    echo "Arguments:"
    echo "  -s, --string <text>    The text string(s) to search for. Can be specified multiple times."
    echo "  <directory>            The path to the directory to search within."
    echo ""
    echo "Options:"
    echo "  --help, -h             Display this help message and exit."
    echo "  --depth                Specifies the folder depth for searching files."
    echo "  --ext=ext1,ext2        Restrict processing to files with specific extensions."
    echo "  --ignore-case          Perform case-insensitive matching."
    echo "  --ignore-binaries      Detects and ignores binary files."
    echo "  --log=FILE             Log output to the specified file."
    echo ""
    echo "Example:"
    echo "  $0 --ignore-case -s 'passwd' -s 'password' /home/user"
    exit 0
}

# --- Default Flags ---
IGNORE_CASE=false
IGNORE_BINARY=false
EXT_FILTER=()
LOG_FILE=""
DEPTH=""
SEARCH_TERMS=()

# --- Parse Options ---
POSITIONAL=()
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ignore-case) IGNORE_CASE=true; shift ;;
        --ignore-binaries) IGNORE_BINARY=true; shift;;
        --ext=*) IFS=',' read -ra EXT_FILTER <<< "${1#*=}"; shift ;;
        --log=*) LOG_FILE="${1#*=}"; shift ;;
        --depth=*) DEPTH="${1#*=}"; shift ;;
        -s|--string)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                SEARCH_TERMS+=("$2")
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        --help|-h) display_help ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]}"

# --- Validate Arguments ---
TARGET_DIRECTORY="$1"

if [ -z "$TARGET_DIRECTORY" ]; then
    echo "Error: Directory argument is missing."
    echo "Run '$0 --help' for usage information."
    exit 1
fi

if [ ! -d "$TARGET_DIRECTORY" ]; then
    echo "Error: Directory '$TARGET_DIRECTORY' not found."
    exit 1
fi

if [ "${#SEARCH_TERMS[@]}" -eq 0 ]; then
    echo "Error: No search terms specified. Use -s or --string to specify text to find."
    exit 1
fi

if [[ -n "$DEPTH" && ! "$DEPTH" =~ ^[0-9]+$ ]]; then
     echo "Error: --depth requires a numeric value."
     exit 1
fi

# --- Logging ---
if [ -n "$LOG_FILE" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# --- Summary ---
echo "--- Recursive Text Search Tool ---"
echo "Directory:              $TARGET_DIRECTORY"
echo "Search terms:           ${SEARCH_TERMS[*]}"
echo "Max search depth:       ${DEPTH:-(unlimited)}"
echo "Case-insensitive:       $IGNORE_CASE"
echo "Extension filter:       ${EXT_FILTER[*]:-(none)}"
echo "Ignore binaries:        $IGNORE_BINARY"
echo "---------------------------------------"
echo

total_matches_found=0

# --- Main File Loop ---
while IFS= read -r -d $'\0' file_path; do

    # --- Text File Check via MIME ---
    mime_type=$(file --mime-type -b "$file_path")
    is_binary=$(file "$file_path" | grep -qE 'binary' && echo true || echo false)

    case "$mime_type" in
        text/*|application/json|application/xml|application/javascript)
            # --- Extension Filtering ---
            if [ "${#EXT_FILTER[@]}" -gt 0 ]; then
                ext="${file_path##*.}"
                match=false
                for allowed_ext in "${EXT_FILTER[@]}"; do
                    if [[ "$ext" == "$allowed_ext" ]]; then
                        match=true
                        break
                    fi
                done
                [ "$match" == false ] && continue
            fi

            # --- Binary file exclusion ---
            if $IGNORE_BINARY && [ "$is_binary" = true ]; then
                continue
            fi

            # --- Search for Terms ---
            for term in "${SEARCH_TERMS[@]}"; do
                grep_opts="-oF"
                $IGNORE_CASE && grep_opts="-oiF"
                
                # Check for existence first to avoid extra processing if 0
                occurrences=$(grep $grep_opts -- "$term" "$file_path" 2>/dev/null | wc -l)

                if [ "$occurrences" -gt 0 ]; then
                    echo "Found match(es) for '$term' in: $file_path"
                    
                    debug_grep_opts="-nF"
                    $IGNORE_CASE && debug_grep_opts="-niF"
                    
                    # We output the matches directly
                    # Use process substitution to avoid subshell variable scope issue
                    while IFS=: read -r lineno line; do
                         if $IGNORE_CASE; then
                            HIGHLIGHTED_LINE=$(echo "$line" | sed "s/$term/\x1b[7m&\x1b[0m/gI")
                        else
                            HIGHLIGHTED_LINE="${line//$term/$'\e[7m'$term$'\e[0m'}"
                        fi
                        printf "     Line %s: %b\n" "$lineno" "$HIGHLIGHTED_LINE"
                    done < <(grep $debug_grep_opts -- "$term" "$file_path")
                    
                    total_matches_found=$((total_matches_found + occurrences))
                fi
            done
            ;;

        *) continue ;;
    esac
done < <(find "$TARGET_DIRECTORY" ${DEPTH:+-maxdepth "$DEPTH"} -type f -print0)

# --- Summary Report ---
echo
echo "--- Search Report ---"
if [ "$total_matches_found" -gt 0 ]; then
    echo "Total matches found: $total_matches_found"
else
    echo "No matches found."
fi
echo "Script finished."
