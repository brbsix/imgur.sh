Bart's Imgur uploader bash script
=================================

- By Bart Nagel <bart@tremby.net>
- Improvements by Tino Sino <robottinosino@gmail.com>
- Improvements by Brian Beffa <brbsix@gmail.com>

Purpose
-------

Upload images to [Imgur](http://imgur.com/) via a small bash script.

History
-------

This is the repository for the Bash script which has been found on [Imgur's
tools page](http://imgur.com/tools) since way back in 2009.

I got infrequent but steady emails over the years with thanks and suggestions
for improvements. A Google search shows the script has been reused and forked
many times over the years. About time this had its own Git repository, so maybe
the improvements can find their way back to the source.

Requirements
------------

- `curl`

### Optional

- `xsel`, `xclip`, or `pbcopy`, to automatically put the URLs on the X selection
  for easy pasting

Instructions
------------

1. Put it somewhere in your path and maybe rename it

        mv imgur.sh ~/bin/imgur

2. Make it executable

        chmod +x ~/bin/imgur

3. *Optional, since [Alan](http://imgur.com/user/Alan) at Imgur kindly provided
   an API key for this script:* stick your API key in the top

        vim ~/bin/imgur

### Uploading images

- Single image

        imgur images/hilarious/manfallingover.jpg

- Multiple images

        imgur images/delicious/cake.png images/exciting/bungeejump.jpg

The URLs will be displayed (and the delete page's URLs will be displayed on
stderr). If you have `xsel`, `xclip`, or `pbcopy`, the URLs will also be put on
the X selection, which you can then usually paste with a middle click.
