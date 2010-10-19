a webserver that serves up html to show the currently playing song in itunes.
optimized for a tiny 800x480 external display, like a mimo usb monitor, though
it could just as easily run in an 800x480 browser window on a large screen.

see (http://www.flickr.com/photos/symmetricalism/5095339235/) for a demo.

requires the rb-appscript gem to talk to itunes.  it works like this:

- server starts up listening on port 2000.

- browser requests http://127.0.0.1:2000/, receives a single document containing
  html, javascript, and css.  the main polling routine fires.

- an ajax request for http://127.0.0.1:2000/track is sent off.

- the server gets a request for /track and pulls some information from itunes
  via applescript.

	- if the track id is the same as what was passed by the browser, a null
	  response is returned so the browser doesn't have to do anything.

	- otherwise, the current track, artist, and album name, with the album
	  art and rating are retrieved.  because itunes sends back album art
	  wrapped in a PICT file, the data blob has to be searched through to
	  pull out the JPEG or PNG data that the browser can understand.  that
	  blob is base64-encoded and returned to the browser as a data: uri to
	  avoid another round-trip to fetch a separate image.

- the browser evaluates the javascript returned, which either does nothing or
  displays a new track name, album, artist, album art image, and rating.

- a timer is set for 500 milliseconds to do this loop again forever.

to use on a secondary monitor, i had trouble finding a webkit browser that could
run full-screen without any menus or anything and display on a secondary
monitor.  i eventually went with [fluid](http://fluidapp.com/) and configured it
to run a browser for http://127.0.0.1:2000/ in full-screen.

# vim:ts=8:tw=80
