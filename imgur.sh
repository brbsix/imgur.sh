#!/bin/bash

# Imgur script by Bart Nagel <bart@tremby.net>
# Improvements by Tino Sino <robottinosino@gmail.com>
# Version 6 or more
# I release this into the public domain. Do with it what you will.
# The latest version can be found at https://github.com/tremby/imgur.sh

# API Key provided by Alan@imgur.com
apikey="b3625162d3418ac51a9ee805b1840452"

# Function to output usage instructions
function usage {
    echo "Usage: $(basename $0) <filename> [<filename> [...]]" >&2
    echo "Upload images to imgur and output their new URLs to stdout. Each one's" >&2
    echo "delete page is output to stderr between the view URLs." >&2
    echo "If xsel, xclip, or pbcopy is available, the URLs are put on the X selection for" >&2
    echo "easy pasting." >&2
}

# Check API key has been entered
if [ -z "$apikey" ]; then
    echo "You first need to edit the script and put your API key in the variable near the top." >&2
    exit 15
fi

# Check arguments
if [ "$1" == "-h" -o "$1" == "--help" ]; then
    usage
    exit 0
elif [ $# -eq 0 ]; then
    echo "No file specified" >&2
    usage
    exit 16
fi

# Check curl is available
type curl &>/dev/null || {
    echo "Couldn't find curl, which is required." >&2
    exit 17
}

clip=""
errors=false

# Loop through arguments
while [ $# -gt 0 ]; do
    file="$1"
    shift

    # Check file exists
    if [ ! -f "$file" ]; then
        echo "File '$file' doesn't exist, skipping" >&2
        errors=true
        continue
    fi

    # Upload the image
    response=$(curl -vF "key=$apikey" -H "Expect: " -F "image=@$file" \
        http://imgur.com/api/upload.xml 2>/dev/null)
    # The "Expect: " header is to get around a problem when using this through
    # the Squid proxy. Not sure if it's a Squid bug or what.
    if [ $? -ne 0 ]; then
        echo "Upload failed" >&2
        errors=true
        continue
    elif echo "$response" | grep -q "<error_msg>"; then
        echo "Error message from imgur:" >&2
        msg="${response##*<error_msg>}"
        echo "${msg%%</error_msg>*}" >&2
        errors=true
        continue
    fi

    # Parse the response and output our stuff
    url="${response##*<original_image>}"
    url="${url%%</original_image>*}"
    deleteurl="${response##*<delete_page>}"
    deleteurl="${deleteurl%%</delete_page>*}"
    echo $url
    echo "Delete page: $deleteurl" >&2

    # Append the URL to a string so we can put them all on the clipboard later
    clip+="$url"
    if [ $# -gt 0 ]; then
        clip+=$'\n'
    fi
done

# Put the URLs on the clipboard if we have xsel or xclip
if [ $DISPLAY ]; then
    if type xsel &>/dev/null; then
        echo -n "$clip" | xsel
    elif type xclip &>/dev/null; then
        echo -n "$clip" | xclip
    elif type pbcopy &>/dev/null; then
        echo -n "$clip" | pbcopy
    else
        echo "Haven't copied to the clipboard: no xsel, xclip, or pbcopy" >&2
    fi
else
    echo "Haven't copied to the clipboard: no \$DISPLAY" >&2
fi

if $errors; then
    exit 1
fi
