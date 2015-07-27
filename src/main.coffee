gerberToSvg = require 'gerber-to-svg'
_           = require 'lodash'
layerOptions = require './layer-options'
idLayer      = require './identify-layer'
build        = require './build-board'

defaultStyle =
  style:
    type: 'text/css',
    _: "
      .Board--board { color: dimgrey; }
      .Board--cu { color: lightgrey; }
      .Board--cf { color: goldenrod; }
      .Board--sm { color: darkgreen; opacity: 0.75; }
      .Board--ss { color: white; }
      .Board--sp { color: silver; }
      .Board--out { color: black; }"


# convert to xml object
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
  ls = layers.filter (layer) ->
    opt = _.find layerOptions, { val: layer.type }
    # return true if the board side of the option matches the board type
    opt?.side is side or opt?.side is 'both'
  #we need to clone as build-board mutates these objects and some are used for
  #both top and bottom
  return _.cloneDeep(ls)


convert = (gerbers, style = defaultStyle, output = 'string') ->
  layers = []
  for g in gerbers
    {svgObj} = convertGerber g.filename, g.gerber
    type = idLayer(g.filename)
    layers.push { svgObj:svgObj, type: type }
  topLayers = filterBoardLayers layers, 'top'
  svgObjTop = build 'top', topLayers
  svgObjTop.svg._.push style
  bottomLayers = filterBoardLayers layers, 'bottom'
  svgObjBottom = build 'bottom', bottomLayers
  svgObjBottom.svg._.push style
  switch output
    when 'string'
        top:gerberToSvg svgObjTop
        bottom: gerberToSvg svgObjBottom
    when 'object'
        top:svgObjTop
        bottom:svgObjBottom


if require.main != module
  module.exports = convert
else
  fs   = require 'fs'
  path = require 'path'
  layers = []
  for p in process.argv.slice(2)
    layers.push({filename: path.basename(p)
      , gerber:fs.readFileSync(p, 'utf8')})
  svg = convert(layers)
  top = fs.openSync('top.svg', 'w')
  bottom = fs.openSync('bottom.svg', 'w')
  fs.writeSync(top, svg.top)
  fs.writeSync(bottom, svg.bottom)
