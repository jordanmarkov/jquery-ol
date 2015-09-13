class OlStyleParser
    _styleCache = { }

    _parseFillStyle: ($element) ->
        if not $element? or $element.length == 0
            return
        else
            new ol.style.Fill color: $element.attr('color') or throw "Fill color is required"

    _parseStrokeStyle: ($element) ->
        if not $element? or $element.length == 0
            return
        else
            properties =
                color: $element.attr('color') or throw "Stroke color is required"
                width: parseFloat $element.attr('width') or throw "Stroke width is required"
            $element.children('ol-property').each ->
                key = $(this).attr('name')
                val = $(this).text()
                val = switch key
                    when 'miterLimit' then parseFloat(val)
                    when 'lineCap' then (
                        if val in ['butt', 'round', 'square'] then val else throw "Usupported lineCap value: '#{ val }'. Supported are 'butt', 'round' or 'square'."
                    )
                    when 'lineJoin' then (
                        if val in ['bevel', 'round', 'miter'] then val else throw "Usupported lineJoin value: '#{ val }'. Supported are 'bevel', 'round' or 'miter'."
                    )
                    when 'lineDash' then (parseFloat(p) for p in val.split(','))
                    else throw "Usupported stroke property: '#{ key }'"
                properties[key] = val
            new ol.style.Stroke properties

    _getCircleProperties: ($element) ->
        properties =
            radius: parseFloat($element.attr('radius')) or throw "Radius is required"
            snaptopixel: $element.attr('snaptopixel') != 'false'
            fill: @_parseFillStyle $element.children('ol-fill')
            stroke: @_parseStrokeStyle $element.children('ol-stroke')
        properties

    _getIconProperties: ($element) ->
        properties =
            src: $element.attr('src') or throw "Icon source is required"
            snaptopixel: $element.attr('snaptopixel') != 'false'
        $element.children('ol-property').each ->
            key = $(this).attr('name')
            val = $(this).text()
            val = switch key
                when 'opacity' or 'scale' or 'rotation' then parseFloat(val)
                when 'anchor' then (parseFloat(x) for x in val.split(','))
                when 'offset' then (parseFloat(x) for x in val.split(','))
                when 'rotateWithView' then val != 'false'
                when 'size' then (parseFloat(x) for x in val.split(','))
                when 'imgSize' then (parseFloat(x) for x in val.split(','))
                when 'anchorOrigin' then val
                when 'anchorXUnits' then val
                when 'anchorYUnits' then val
                when 'crossOrigin' then val
                when 'offsetOrigin' then val
                else throw "Usupported icon property: '#{ key }'"
            properties[key] = val
        properties

    _getRegularShapeProperties: ($element) ->
        properties =
            radius: parseFloat($element.attr('radius')) or throw "Radius is required"
            snaptopixel: $element.attr('snaptopixel') != 'false'
            fill: @_parseFillStyle $element.children('ol-fill')
            stroke: @_parseStrokeStyle $element.children('ol-stroke')
        $element.children('ol-property').each ->
            key = $(this).attr('name')
            val = $(this).text()
            val = switch key
                when 'points' then parseFloat(val)
                when 'radius1' then parseFloat(val)
                when 'radius2' then parseFloat(val)
                when 'angle' then parseFloat(val)
                when 'rotation' then parseFloat(val)
                else throw "Usupported regular shape property: '#{ key }'"
            properties[key] = val
        properties

    _parseImageStyle: ($element) ->
        if not $element? or $element.length == 0
            return
        else
            if $element.length != 1 then throw "Expected exactly 1 image style, #{ $element.length } given."
            switch $element.attr('type')
                when 'circle' then new ol.style.Circle @_getCircleProperties($element)
                when 'icon' then new ol.style.Icon @_getIconProperties($element)
                when 'regular-shape' then new ol.style.RegularShape @_getRegularShapeProperties($element)
                else throw "Usupported image type. Supported are 'circle', 'icon' or 'regular-shape'."

    _parseSymbolizer: ($element) ->
        new ol.style.Style
            image: @_parseImageStyle $element.children('ol-image')
            stroke: @_parseStrokeStyle $element.children('ol-stroke')
            fill: @_parseFillStyle $element.children('ol-fill')

    _parseZoomStyle: ($element) ->
        predicate = switch
            when $element.attr 'lt' then (zoom) -> zoom < parseFloat($element.attr 'lt')
            when $element.attr 'lte' then (zoom) -> zoom <= parseFloat($element.attr 'lte')
            when $element.attr 'gt' then (zoom) -> zoom > parseFloat($element.attr 'gt')
            when $element.attr 'gte' then (zoom) -> zoom >= parseFloat($element.attr 'gte')
            when $element.attr 'eq' then (zoom) -> zoom == parseFloat($element.attr 'eq')
            when $element.attr 'ne' then (zoom) -> zoom != parseFloat($element.attr 'ne')
            else throw "None of the supported operators found: 'lt', 'lte', 'gt', 'gte', 'eq' or 'ne'."
        return {
            predicate: predicate
            style: @_parseSymbolizer $element
        }

    _parseStyle: ($element) ->
        symbolizers = []
        $element.children('ol-resolution').each (idx, val) =>
            symbolizers.push(@_parseZoomStyle $(val))
        symbolizers.push
            predicate: (zoom) -> true
            style: @_parseSymbolizer $element

        #(feature, resolution) => [@_parseSymbolizer $element]
        (feature, resolution) =>
            style = (sym.style for sym in symbolizers when sym.predicate(resolution))
            style[...1]

    parseStyles: ($element) ->
        $element.children('ol-style').each (idx, styleElement) =>
            $this = $(styleElement)
            name = $this.attr('name') or throw "Style name is required"
            _styleCache[name] = @_parseStyle $this
            return

    getStyle: (name) ->
        if name of _styleCache
            _styleCache[name]
        else
            throw "Unknown style name: '#{ name }'"
