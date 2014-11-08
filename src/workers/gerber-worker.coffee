# webworker to handle converting gerber to svg
# pull in the library
gerberToSvg = require 'gerber-to-svg'

# convert to xml object function
convertGerber = (filename, gerber) ->
  # try it as a gerber first
  if typeof gerber is 'object' then obj = gerber
  else
    try
      obj = gerberToSvg gerber, { object: true }
    catch e
      # if that errors, try it as a drill
      try
        obj = gerberToSvg gerber, { drill: true, object: true}
      catch e2
        #if that errors, too, return the original error message
        obj = {}
  # take the xmlObject and get the string
  if obj.svg? then string = gerberToSvg obj else string = ''
  # return the message
  { filename: filename, svgObj: obj, svgString: string }

self.addEventListener 'message', (e) ->
  gerber = e.data.gerber
  filename = e.data.filename
  # post the message
  self.postMessage convertGerber filename, gerber
, false