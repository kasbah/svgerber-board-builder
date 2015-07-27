fs           = require 'fs'
path         = require 'path'
gerberToSvg  = require 'gerber-to-svg'
layerOptions = require './layer-options'
idLayer      = require './identify-layer'
lodash = require 'lodash'

# convert to xml object function
convertGerber = (filename, gerber) ->
  # warnings array
  warnings = []
  # if it's an object, half our job is done
  if typeof gerber is 'object' then obj = gerber
  else
    # try it as a gerber first
    try
      obj = gerberToSvg gerber, { object: true, warnArr: warnings }
    catch e
      # if that errors, try it as a drill
      try
        warnings = []
        obj = gerberToSvg gerber, {
          drill: true, object: true, warnArr: warnings
        }
      catch e2
        warnings = []
        obj = {}
  # take the xmlObject and get the string
  if obj.svg? then string = gerberToSvg obj else string = ''
  # return the message
  { filename: filename, svgObj: obj, svgString: string, warnings: warnings }

filterBoardLayers = (layers, side) ->
  layers.filter (layer) ->
    opt = lodash.find layerOptions, { val: layer.type }
    # return true if the board side of the option matches the board type
    opt?.side is side or opt?.side is 'both'

layers = []
for p in process.argv.slice(2)
  file = fs.readFileSync(p, 'utf8')
  {svgObj, filename} = convertGerber(path.basename(p), file)
  type = idLayer(filename)
  layers.push({svgObj:svgObj, type: type})

topLayers = filterBoardLayers(layers, 'top')
