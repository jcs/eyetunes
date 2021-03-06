#!/usr/bin/ruby
#
# a tiny web server (runs on port 2000) that outputs some auto-refreshing
# (every 500ms through ajax, only if the track changes) html displaying the
# name and cover art of the currently playing song in itunes
#
# optimized for a tiny display (800x480) running a full-screen webkit-based web
# browser, uses webkit's marquee css to scroll long track names back and forth
# smoothly.
#
# Copyright (c) 2010-2012 joshua stein <jcs@jcs.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "rubygems"

# from the "rb-appscript" gem
require "appscript"

# itunes 10.6.3 fix
require File.dirname(__FILE__) + "/appscript_itunes_fix"

require "webrick"

class CurrentTrack < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    case request.path
    when "/"
      response.status = 200
      response["Content-Type"] = "text/html"
      response.body = <<END
        <html>
        <head>
        <script type="text/javascript">
          var dbid = "";
          var paused = false;

          function fetch() {
            var req = new XMLHttpRequest();
            req.onload = function() {
              eval(req.responseText);

              if (paused)
                document.body.className = "paused";
              else
                document.body.className = "";

              setTimeout(fetch, 500);
            };
            req.onerror = function() {
              setTimeout(fetch, 500);
            };
            req.open("GET", "/track?dbid=" + dbid + "&paused=" +
              (paused ? 1 : 0), true);
            req.send(null);
          }
        </script>
        <style type="text/css">
          body {
            background-color: black;
            font-family: "helvetica neue";
            font-weight: bold;
            overflow-y: hidden;
          }
          ul {
            list-style: none;
            margin: 0px;
            padding: 0px;
            width: 375px;
          }
          li {
            line-height: 0.9em;
            margin: 0px 0px 1em 0.5em;
            padding: 0px;
            text-indent: -0.5em;
          }
          img#art {
            left: 12px;
            position: absolute;
            top: 90px;
            width: 375px;
          }
          div#track, div#artistalbum {
            left: 410px;
            letter-spacing: -0.05em;
            position: absolute;
          }
          div#track {
            color: white;
            left: 10px;
            font-size: 50pt;
            top: 0px;
            overflow-x: -webkit-marquee;
            -webkit-marquee-direction: backwards;
            -webkit-marquee-style: alternate;
            -webkit-marquee-speed: normal;
            -webkit-marquee-increment: small;
            white-space: nowrap;
           }
          div#artistalbum {
            font-size: 40pt;
            top: 90px;
          }
          li#artist {
            color: #bbb;
          }
          li.long {
            font-size: 35pt;
          }
          li#album {
            color: #999;
          }
          li#stars {
            color: #777;
            font-size: 40pt;
          }
          li#stars span.nostar {
            color: #444;
          }
          span.year {
            color: #666;
          }
          body.paused {
            opacity: 0.3;
          }
          body.paused div#track {
            overflow-x: hidden;
          }
        </style>
        </head>
        <body>
        <div id="track"></div>
        <img id="art">
        <div id="artistalbum">
        <ul>
        <li id="artist"></li>
        <li id="album"></li>
        <li id="stars"></li>
        </div>
        <script type="text/javascript">
          fetch();
        </script>
        </body></html>
END

    when "/track"
      track = nil
      dbid = ""
      paused = true
      radio = false
      radio_title = nil
      begin
        if Appscript.app("System Events").processes["iTunes"].get
          app = Appscript.app.by_name("iTunes", ITunesFix)

          track = app.current_track
          if track.kind.get.to_s.match(/^Internet audio/)
            radio = true
            radio_title = app.current_stream_title.get

            # fudge so we still update when the track changes
            dbid = MD5.hexdigest(radio_title)
          else
            dbid = track.database_ID.get.to_s
          end

          if app.player_state.get != :paused
            paused = false
          end
        end
      rescue
      end

      if dbid == request.query["dbid"].to_s &&
      ((request.query["paused"] == "1") == paused)
        response.status = 200
        response["Content-Type"] = "application/javascript"
        response.body = ";"
      else
        artwork = nil
        artwork_type = nil
        title = ""
        artist = ""
        album = ""
        stars = ""
        year = ""

        if radio
          pieces = radio_title.split(" - ")

          artist = pieces[0]
          title = pieces[1]
          album = track.name.get.to_s

        elsif dbid != ""
          begin
            if track.artworks.get
              data = track.artworks[1].data_.get.data

              case track.artworks[1].format.get.to_s
              when /PNG/
                artwork_type = "png"
                artwork = extract_png(data)
              when /JPEG/
                artwork_type = "jpeg"
                artwork = extract_jpeg(data)
              else
                artwork = nil
              end
            end
          rescue
          end

          title = track.name.get
          artist = track.artist.get
          album = track.album.get

          if (year = track.year.get.to_i) == 0
            year = ""
          else
            year = " (#{year})"
          end

          rating = track.rating.get.to_i
          stars = ((1 .. (rating.to_f / 20.0).floor).to_a.map{ "&#9733;" } +
            [ "<span class=\\\"nostar\\\">" ] +
            (1 .. ((100.0 - rating.to_f) / 20.0).floor).to_a.map{ "&#9734;" } +
            [ "</span>" ]).join("")
        end

        if title.to_s == ""
          title = "Unknown Track"
        end

        if artist.to_s == ""
          artist = "Unknown Artist"
        end

        if album.to_s == ""
          album = "Unknown Album"
        end

        if artwork
          artwork = "data:image/#{artwork_type};base64," +
            [ artwork ].pack("m").gsub(/\n/, "")
        else
          artwork = "data:image/gif;base64,R0lGODlhAQABAIAAAP///" +
            "wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
        end

        response.status = 200
        response["Content-Type"] = "application/javascript"
        response.body = <<END
          document.getElementById("track").innerHTML =
            "#{escape_js(title.downcase)}";
          document.getElementById("artist").innerHTML =
            "#{escape_js(add_breakpoints(artist.downcase))}";
          document.getElementById("album").innerHTML =
            "#{escape_js(add_breakpoints(album.downcase))}" +
            "<span class=\\\"year\\\">#{escape_js(year)}</span>";
          document.getElementById("art").src = "#{artwork}";
          document.getElementById("stars").innerHTML = "#{stars}";

          tlen = document.getElementById("artist").innerHTML.length +
            document.getElementById("album").innerHTML.length;

          document.getElementById("artist").className =
            document.getElementById("album").className = (tlen > 27 ? "long" :
            "");

          dbid = "#{dbid}";
          paused = #{paused ? "true" : "false"};
END
      end
    end
  end

private 
  def escape_js(str)
    str.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("&", "&amp;")
  end

  # let the browser know it can break words at things other than spaces
  def add_breakpoints(str)
    str.gsub(/([\.\/\+\-])/, '\1' + "<wbr/>")
  end

  # seek past a possible PICT header and look for a jpeg
  def extract_jpeg(data)
    pos = 0
    while pos + 11 < data.length
      head = data[pos, 11]

      if head.to_s.match(Regexp.new('^\xff\xd8\xff...(JFIF|Exif)\x00', nil, "n"))
        return data[pos ... data.length]
      else
        pos += 1
      end
    end

    return ""
  end

  # or a png
  def extract_png(data)
    pos = 0
    while pos + 8 < data.length
      head = data[pos, 8]

      if head.to_s == "\x89PNG\r\n\x1A\n".b
        return data[pos ... data.length]
      else
        pos += 1
      end
    end

    return ""
  end
end

s = WEBrick::HTTPServer.new(
  :Port => 2000,
  :Logger => WEBrick::Log.new("/dev/null"),
  :AccessLog => [ nil, nil ]
)
s.mount "/", CurrentTrack
Signal.trap(2) { s.shutdown }
s.start
