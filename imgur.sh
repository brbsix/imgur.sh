#!/bin/bash

# Imgur script by Bart Nagel <bart@tremby.net>
# Improvements by Tino Sino <robottinosino@gmail.com>
# Improvements by Brian Beffa <brbsix@gmail.com>
# Version 6 or more
# I release this into the public domain. Do with it what you will.
# The latest version can be found at https://github.com/brbsix/imgur.sh

# API Key provided by Alan@imgur.com
APIKEY='b3625162d3418ac51a9ee805b1840452'

# Output error message to stderr
error(){
    echo "ERROR: $*" >&2
}

# Upload image
upload(){
    # The "Expect: " header is to get around a problem when using this through
    # the Squid proxy. Not sure if it's a Squid bug or what.
    curl -sSvF "key=$APIKEY" -H 'Expect: ' -F "image=@$1" \
        http://imgur.com/api/upload.xml
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

# Empty out the vars
clip=
errors=0

# Loop through arguments
for file in "$@"; do

    # Ensure file exists
    if [[ ! -f $file ]]; then
        error "File '$file' doesn't exist, skipping..."
        ((++errors))
        continue
    # Ensure file is readable
    elif [[ ! -r $file ]]; then
        error "File '$file' is not readable, skipping..."
        ((++errors))
        continue
    fi

    # Upload the image
    # Capture stderr, stdout and the return code in their respective variables
    eval "$({ stderr=$({ stdout=$(upload "$file"); returncode=$?; } 2>&1; declare -p stdout returncode >&2); declare -p stderr; } 2>&1)"

    # Check whether the command exited with a non-zero
    # exit code or empty stdout
    if (( returncode != 0 )) || [[ -z $stdout ]]; then
        error 'Upload failed'
        [[ -z $stderr ]] || {
            echo 'Error message from curl:' >&2
            echo "$stderr" >&2
        }
        ((++errors))
        continue
    elif grep -q '<error_msg>' <<<"$stdout"; then
        echo 'Error message from imgur:' >&2
        msg="${stdout##*<error_msg>}"
        echo "${msg%%</error_msg>*}" >&2
        ((++errors))
        continue
    fi

    # Parse the response and output our stuff
    url="${stdout##*<original_image>}"
    url="${url%%</original_image>*}"
    deleteurl="${stdout##*<delete_page>}"
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

# exit with the correct exit code
(( errors == 0 ))
