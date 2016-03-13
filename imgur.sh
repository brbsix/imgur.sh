#!/bin/bash

# Imgur script by Bart Nagel <bart@tremby.net>
# Improvements by Tino Sino <robottinosino@gmail.com>
# Version 6 or more
# I release this into the public domain. Do with it what you will.
# The latest version can be found at https://github.com/tremby/imgur.sh

# API Key provided by Alan@imgur.com
APIKEY='b3625162d3418ac51a9ee805b1840452'

# Output error message to stderr
error(){
    echo "ERROR: $*" >&2
}

# Output usage instructions
usage(){
    cat >&2 <<-EOF
	Usage: ${0##*/} <filename> [<filename> [...]]
	Upload images to imgur and output their new URLs to stdout.
	Each one's delete page is output to stderr between the view URLs.
	If xsel, xclip, or pbcopy is available, the URLs are put on
	the X selection for easy pasting.
	EOF
}

# Check API key has been entered
if [[ -z $APIKEY ]]; then
    error 'No API key'
    exit 15
fi

# Check arguments
if (( $# == 0 )); then
    error 'No file specified'
    exit 1
elif [[ $# -eq 1 && $1 =~ ^(-h|--help)$ ]]; then
    usage
    exit 0
fi

# Check curl is available
hash curl &>/dev/null || {
    error "Couldn't find curl, which is required"
    exit 1
}

clip=
errors=false

# Loop through arguments
while (( $# > 0 )); do
    file="$1"
    shift

    # Check file exists
    if [[ ! -f $file ]]; then
        error "File '$file' doesn't exist, skipping"
        errors=true
        continue
    fi

    # Upload the image
    response=$(curl -vF "key=$APIKEY" -H 'Expect: ' -F "image=@$file" \
               http://imgur.com/api/upload.xml 2>/dev/null)

    # The "Expect: " header is to get around a problem when using this through
    # the Squid proxy. Not sure if it's a Squid bug or what.
    if (( $? != 0 )); then
        error 'Upload failed'
        errors=true
        continue
    elif grep -q '<error_msg>' <<<"$response"; then
        echo 'Error message from imgur:' >&2
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
    echo "$url"
    echo "Delete page: $deleteurl" >&2

    # Append the URL to a string so we can put them all on the clipboard later
    clip+="$url"
    if (( $# > 0 )); then
        clip+=$'\n'
    fi
done

# Put the URLs on the clipboard if we have xsel or xclip
if [[ -n $DISPLAY ]]; then
    if hash xsel &>/dev/null; then
        echo -n "$clip" | xsel
    elif hash xclip &>/dev/null; then
        echo -n "$clip" | xclip
    elif hash pbcopy &>/dev/null; then
        echo -n "$clip" | pbcopy
    else
        error "Haven't copied to the clipboard: no xsel, xclip, or pbcopy"
    fi
else
    error "Haven't copied to the clipboard: no \$DISPLAY"
fi

if "$errors"; then
    exit 1
fi
