###eyetunes

eyetunes is a system for displaying the current iTunes track information on
a secondary monitor or other small window.  It shows the track name (scrolling
it when it's too long), artist, album, star rating, and album art.  The entire
window fades darker when iTunes is paused.

It is optimized for an 800x600 resolution screen, like a MiMo USB monitor.

[![](http://i.imgur.com/GgaidhN.jpg)](http://i.imgur.com/GgaidhN.jpg)

####Usage

0. Install the `rb-appscript` gem.

	`$ sudo gem install rb-appscript`

1. Run the `eyetunes.rb` script to start the web server.

	`$ ruby eyetunes.rb &`

2. Start the GUI/browser with the specified geometry of your secondary display:

	`$ ./eyetunesgui -x 1920 -y 0 -w 800 -h 600 &`

####How it works

eyetunes.rb is a Ruby script that uses the `rb-appscript` gem to talk to
iTunes via AppleScript.  It also runs a WEBrick web server on 127.0.0.1
port 2000 where it serves a simple HTML page with some JavaScript.

Pointing a web browser at `http://127.0.0.1:2000/` will load a basic black
page and position the text labels that will hold the track information.  An
Ajax loop starts and polls back to the web server every 500 milliseconds,
which retrieves the current track information from iTunes and displays it
on the page.

- If the track id is the same as what was passed by the browser, a null
  response is returned so the browser doesn't have to do anything.

- Otherwise, the current track, artist, and album name, with the album art and
  rating are retrieved.  Because iTunes sends back album art wrapped in a PICT
file, the data blob has to be searched through to pull out the JPEG or PNG data
that the browser can understand.  That blob is base64-encoded and returned to
the browser as a `data:` URI to avoid another round-trip to fetch a separate
image.

####Standalone browser

While eyetunes will work in any standard web browser, displaying it on a
separate monitor without any window chrome, in full-screen mode while not
causing problems with other full-screen apps, is more complicated than it
probably should be.

Previous versions were using a [Fluid](http://fluidapp.com/) browser configured
to load `http://127.0.0.1:2000/` in full-screen, but this required manually
positioning the browser, adjusting the settings, and then having to re-do it if
it ever failed to load the eyetunes page for some reason.  Fluid also seems to
be broken on OS X Mavericks.

Now a standalone browser is included which creates a small Cocoa window with a
WebKit frame hard-coded to load `http://127.0.0.1:2000/` at the specified screen
geometry.

To re-compile the browser, install XCode and execute `xcodebuild` in the `gui`
directory.
