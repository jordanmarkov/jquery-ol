class OlParser
    _styleParser = new OlStyleParser()
    _mapProjection = 'EPSG:3857'
    _configProjection = 'EPSG:4326'
    _map = null
    _layers = []

    _addLayer: (layer) -> _layers.push layer

    _isDomNode: (obj) ->
        if typeof Node is 'object'
            obj instanceof Node
        else
            obj? and typeof obj is 'object' and typeof obj.nodeType is "number" and typeof obj.nodeName is "string"

    _isDomElement: (obj) ->
        if typeof HTMLElement is "object"
            obj instanceof HTMLElement
        else
            obj? and typeof obj is 'object' and obj.nodeType == 1 and typeof obj.nodeName is "string"

    _parseFixedStrategy: ($element) ->
        bboxCP = (parseFloat(coord.trim()) for coord in $element.text().split(','))
        bboxMP = ol.proj.transformExtent bboxCP, _configProjection, _mapProjection
        () -> [ bboxMP ]

    _parseVectorStrategy: ($element) ->
        $strategyElement = $element.children('ol-strategy')
        if $strategyElement.length > 1 then throw "Expected 0 or 1 strategies, #{ $strategyElement.length } given."

        $this = $strategyElement
        if $this.length == 0 or $this.attr('type') == 'all'
            ol.loadingstrategy.all
        else
            switch $this.attr 'type'
                when 'bbox' then ol.loadingstrategy.bbox
                when 'fixed' then @_parseFixedStrategy $this
                else throw "Usupported strategy type: '#{ $this.attr 'type' }'"

    _parseGeoJsonSourceProperties: ($element) ->
        properties = { }
        $element.children('ol-property').each ->
            key = $(this).attr('name')
            val = $(this).text()
            if not key
                throw "Property name cannot be empty in source ol-property"
            if properties[key]?
                throw "Property name cannot be duplicated in source ol-property"
            properties[key] = val
        properties

    _parseGeoJsonSource: ($element) ->
        if not $element.attr('src')?
            jsonContent = $element.text()
            source = new ol.source.Vector
                features: new ol.format.GeoJSON().readFeatures JSON.parse(jsonContent),
                    dataProjection: $element.attr('projection') or throw "'projection' is required for GeoJson layer"
                    featureProjection: _mapProjection
            source.oljq_refresh = =>
                return
            source
        else
            format = new ol.format.GeoJSON
                defaultProjection: $element.attr('projection') or throw "'projection' is required for GeoJson layer"
            that = this
            loader = (extent, resolution, projection) ->
                layerSource = @
                projectionString = projection.getCode()
                extent = if extent.any((c) -> c == Infinity or c == -Infinity) then projection.getExtent() else extent
                ajaxData = $.extend {}, layerSource.getProperties(), {
                    srs: projectionString
                    extent: extent.join(',')
                    resolution: resolution
                }
                $.ajax
                    url: $element.attr('src')
                    data: ajaxData
                    cache: false
                    dataType: 'json'
                    success: (data, textStatus, jqXHR) ->
                        features = format.readFeatures data,
                            dataProjection: format.defaultDataProjection
                            featureProjection: _mapProjection
                        layerSource.addFeatures features
                    error: (jqXHR, textStatus, errorThrown) ->
                        console.error  "ajax error for '#{ $element.attr('src') }': #{ textStatus }, #{ errorThrown }"
                return
            strategy = @_parseVectorStrategy $element

            source = new ol.source.Vector
                loader: loader
                strategy: strategy
                projection: _mapProjection
            source.setProperties that._parseGeoJsonSourceProperties $element

            if $element.attr('refresh')?
                refreshInterval = parseInt($element.attr('refresh'), 10)
                if refreshInterval > 0
                    setInterval (=>
                        view = _map.getView()
                        loader.call(source, view.calculateExtent(_map.getSize()), view.getResolution(), view.getProjection())
                    ), refreshInterval

            source.oljq_refresh = =>
                if not _map?
                    return
                view = _map.getView()
                loader.call(source, view.calculateExtent(_map.getSize()), view.getResolution(), view.getProjection())
                return

            source

    _parseVectorSource: ($element) ->
        $sourceElement = $element.children('ol-source')
        if $sourceElement.length != 1 then throw "Expected exactly 1 source, #{ $sourceElement.length } given."

        $this = $sourceElement
        if $this.attr('type') != 'vector' then throw "Usupported vector source type: '#{ $this.attr 'type' }'"

        source = switch $this.attr 'format'
            when 'geojson' then @_parseGeoJsonSource $this
            when 'inline' then @_parseInlineSource $this
            else throw "Usupported vector source format type: '#{ $this.attr 'format' }'"

        source.oljq_refresh = =>
            return
        source

    _parseVectorLayer: ($element) ->
        layerStyleName = $element.attr 'style-id'
        new ol.layer.Vector
            source: @_parseVectorSource $element
            name: $element.attr 'name'
            style: _styleParser.getStyle layerStyleName

    _parseMapQuestSource: ($element) ->
        layerName = $element.attr 'layer'
        if layerName not in ['osm', 'sat', 'hyb'] then throw "Unsupported MapQuest layer: '#{ layerName }'. Valid options are 'osm', 'sat' or 'hyb'."
        source = new ol.source.MapQuest layer: layerName
        source.oljq_refresh = =>
            return
        source

    _parseOSMSource: ($element) ->
        urlFormat = $element.attr 'url-format' or undefined
        source = new ol.source.OSM url: urlFormat
        source.oljq_refresh = =>
            return
        source

    _parseTileSource: ($element) ->
        $sourceElements = $element.children('ol-source')
        if $sourceElements.length != 1 then throw "Expected exactly 1 source, #{ $sourceElements.length } given."

        $this = $($sourceElements[0])
        source = switch $this.attr 'type'
            when 'mapQuest' then @_parseMapQuestSource $this
            when 'osm' then @_parseOSMSource $this
            else throw "Usupported tile source type: '#{ $this.attr 'type' }'"
        source.oljq_refresh = =>
            return
        source

    _parseTileLayer: ($element) ->
        new ol.layer.Tile
            source: @_parseTileSource $element
            name: $element.attr 'name'

    _parseOlLayers: ($element) ->
        layers = []
        $element.children('ol-layer').each (idx, olLayerElement) =>
            $this = $(olLayerElement)
            layer = switch $this.attr 'type'
                when 'vector' then @_parseVectorLayer $this
                when 'tile' then @_parseTileLayer $this
                else throw "Usupported layer type: '#{ $this.attr 'type' }'"
            layers.push layer
            @_addLayer layer
            return
        layers

    _parseView: ($element) ->
        $viewElements = $element.children('ol-view')
        if $viewElements.length != 1 then throw "Expected exactly 1 view, #{ $viewElements.length } given."
        $this = $($viewElements[0])

        properties = { }
        $this.children('ol-property').each ->
            key = $(this).attr('name')
            val = $(this).text()
            val = switch key
                when 'center' then (parseFloat(coord) for coord in val.split(','))
                when 'constrainRotation' then switch val
                    when 'true' then true
                    when 'false' then false
                    else parseInt(val, 10)
                when 'enableRotation' then val != 'false'
                when 'extent' then (parseFloat(coord) for coord in val.split(','))
                when 'maxResolution' then parseFloat(val)
                when 'minResolution' then parseFloat(val)
                when 'maxZoom' then parseInt(val, 10)
                when 'minZoom' then parseInt(val, 10)
                when 'projection' then val
                when 'resolution' then parseFloat(val)
                when 'resolutions' then (parseFloat(coord) for coord in val.split(','))
                when 'rotation' then parseFloat(val)
                when 'zoom' then parseInt(val, 10)
                when 'zoomFactor' then parseFloat(val)
                else throw "Usupported view property: '#{ key }'"
            properties[key] = val
        _mapProjection = properties.projection = properties.projection ? _mapProjection
        if properties.center? then properties.center = ol.proj.transform properties.center, _configProjection, properties.projection
        if properties.extent? then properties.extent = ol.proj.transformExtent properties.extent, _configProjection, properties.projection
        new ol.View properties

    _getOlConfig: ($element) ->
        deferred = $.Deferred()
        if $element.attr('src')
            $.ajax
                url: $element.attr 'src'
                dataType: "xml"
                cache: true
                success: (data, textStatus, jqxhr) =>
                    deferred.resolve $(data).children('ol-configuration')
                error: (jqXHR, textStatus, errorThrown) =>
                    deferred.reject textStatus
        else
            deferred.resolve  $($.parseXML $element.children('script[type="application/xml"]').text()).children('ol-configuration')
        deferred

    getLayers: -> _layers.slice()

    getVectorLayers: -> (layer for layer in _layers when layer.get('source') instanceof ol.source.Vector)

    parseMap: (element, options) ->
        _configProjection = if options.projection then options.projection else 'EPSG:4326'

        $element = switch
            when element instanceof $ then element
            when typeof element is 'string' then $("#{ element }")
            when @_isDomNode element then $(element)
            else throw "Unknown element"
        if $element.length == 0 then throw "Unknown element"

        _configProjection = if $element.attr 'projection' then $element.attr 'projection' else _configProjection

        @_getOlConfig($element).then ($olConfig) =>
            _styleParser.parseStyles $olConfig

            map = new ol.Map
                target: $element[0]
                view: @_parseView $olConfig
                layers: @_parseOlLayers $olConfig
            _map = map

            interactions = new OlInteractions(map)
            interactions.dragCursor()
            interactions.hoverCursor()
            interactions.popups()
            interactions.tooltips()

            setTimeout (=>
                $element.trigger
                    type: 'jquery-ol.map.initialized'
                    map: map
            ), 10

            return
