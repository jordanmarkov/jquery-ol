class OlParser
    _styleParser = new OlStyleParser()
    _mapProjection = 'EPSG:3857'

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

    _parseGeoJsonSource: ($element) ->
        if not $element.attr('src')?
            # jQuery adds HTML comments to CDATA content (most probably), so remove it
            #jsonContent = $element.html()
            #jsonContent = jsonContent.trimStart('<!--[CDATA[').trimEnd(']]-->').trimStart('<![CDATA[').trimEnd(']]>')
            # When parsing actual XML there's no such problem
            jsonContent = $element.text()
            new ol.source.Vector
                features: new ol.format.GeoJSON().readFeatures JSON.parse(jsonContent),
                    dataProjection: $element.attr('projection') or throw "'projection' is required for GeoJson layer"
                    featureProjection: _mapProjection
        else
            new ol.source.Vector
                format: new ol.format.GeoJSON
                    defaultProjection: $element.attr('projection') or throw "'projection' is required for GeoJson layer"
                url: $element.attr('src')

    _parseVectorSource: ($element) ->
        $sourceElement = $element.children('ol-source')
        if $sourceElement.length != 1 then throw "Expected exactly 1 source, #{ $sourceElement.length } given."

        $this = $sourceElement
        if $this.attr('type') != 'vector' then throw "Usupported vector source type: '#{ $this.attr 'type' }'"

        switch $this.attr 'format'
            when 'geojson' then @_parseGeoJsonSource $this
            when 'inline' then @_parseInlineSource $this
            else throw "Usupported vector format type: '#{ $this.attr 'format' }'"

    _parseVectorLayer: ($element) ->
        layerStyleName = $element.attr 'style-id'
        new ol.layer.Vector
            source: @_parseVectorSource $element
            name: $element.attr 'name'
            style: _styleParser.getStyle layerStyleName

    _parseMapQuestSource: ($element) ->
        layerName = $element.attr 'layer'
        if layerName not in ['osm', 'sat', 'hyb'] then throw "Unsupported MapQuest layer: '#{ layerName }'. Valid options are 'osm', 'sat' or 'hyb'."
        new ol.source.MapQuest layer: layerName

    _parseOSMSource: ($element) ->
        urlFormat = $element.attr 'url-format' or undefined
        new ol.source.OSM url: urlFormat

    _parseTileSource: ($element) ->
        $sourceElements = $element.children('ol-source')
        if $sourceElements.length != 1 then throw "Expected exactly 1 source, #{ $sourceElements.length } given."

        $this = $($sourceElements[0])
        switch $this.attr 'type'
            when 'mapQuest' then @_parseMapQuestSource $this
            when 'osm' then @_parseOSMSource $this
            else throw "Usupported tile source type: '#{ $this.attr 'type' }'"

    _parseTileLayer: ($element) ->
        new ol.layer.Tile
            source: @_parseTileSource $element
            name: $element.attr 'name'

    _parseOlLayers: ($element) ->
        layers = []
        $element.children('ol-layer').each (idx, olLayerElement) =>
            $this = $(olLayerElement)
            layers.push switch $this.attr 'type'
                when 'vector' then @_parseVectorLayer $this
                when 'tile' then @_parseTileLayer $this
                else throw "Usupported layer type: '#{ $this.attr 'type' }'"
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
        if properties.center? then properties.center = ol.proj.transform properties.center, 'EPSG:4326', properties.projection
        if properties.extent? then properties.extent = ol.proj.transformExtent properties.extent, 'EPSG:4326', properties.projection
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

    parseMap: (element) ->
        $element = switch
            when element instanceof $ then element
            when typeof element is 'string' then $("#{ element }")
            when @_isDomNode element then $(element)
            else throw "Unknown element"
        if $element.length == 0 then throw "Unknown element"

        $popupElement = $('<div>').appendTo($element)
        popupOverlay = new ol.Overlay
            element: $popupElement[0]
            positioning: 'bottom-center'
            stopEvent: false

        @_getOlConfig($element).then ($olConfig) =>
            _styleParser.parseStyles $olConfig

            map = new ol.Map
                target: $element[0]
                view: @_parseView $olConfig
                layers: @_parseOlLayers $olConfig
            map.addOverlay popupOverlay

            map.on 'moveend', (e) =>
                map.getTarget().style.cursor = ''
                return

            map.on 'pointerdrag', (e) =>
                map.getTarget().style.cursor = 'move'
                return

            map.on 'click', (e) =>
                pixel = map.getEventPixel e.originalEvent
                feature = map.forEachFeatureAtPixel pixel, (feature, layer) => feature
                if feature and feature.get('href')
                    $.ajax
                        url: feature.get('href')
                        cache: false
                        dataType: 'html'
                        success: (data, textStatus, jqXHR) ->
                            htmlData = $.parseHTML data
                            if htmlData.length > 1
                                # multiple html elements returned, wrap them
                                htmlData = $('<div>').html(htmlData)
                            title = htmlData.children('h1,h2,h3,h4,h5,h6').first()
                            if title
                                htmlData.detach('h1:first,h2:first,h3:first,h4:first,h5:first,h6:first')
                            popupOverlay.setPosition e.coordinate
                            $popupElement.popover
                                placement: 'top'
                                html: 'true'
                                container: 'body'
                                content: htmlData
                                title: title
                            $popupElement.popover 'show'
                        error: (jqXHR, textStatus, errorThrown) ->
                            $contentElement.html($('<div>').attr 'class': 'ol-popup-loading-error')
                else
                    $popupElement.popover 'destroy'
                return

            map.on 'pointermove', (e) =>
                if e.dragging
                    map.getTarget().style.cursor = 'move'
                else
                    pixel = map.getEventPixel e.originalEvent
                    feature = map.forEachFeatureAtPixel pixel, (feature, layer) => feature
                    if feature and feature.get('href')
                        map.getTarget().style.cursor = 'pointer'
                    else
                        map.getTarget().style.cursor = ''
                return
            map
