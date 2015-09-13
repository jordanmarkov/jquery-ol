do ->
    class JqOpenLayers
        constructor: (@element, @options) ->
            @$element = $(@element).setUniqueId()
            @elementId = @$element.attr('id')

            @epsg4326 = new ol.proj.get('EPSG:4326')
            @epsg3857 = new ol.proj.get('EPSG:3857')

            @settings = $.extend $.fn.jqOpenLayers.defaults, @options

            @settings.coords = switch
                when not @settings.coords? then [0, 0]
                when typeof @settings.coords is 'string' then (parseFloat(coord) for coord in @settings.coords.split(','))
                else @settings.coords

            @settings.zoom ?= 1

            @map = null
            @mapView = null

            @$element

        initMapFromHtml: ->
            @map = new OlParser().parseMap @$element

        initMap: ->
            @mapView = new ol.View
                center: ol.proj.transform(@settings.coords, @epsg4326, @epsg3857)
                zoom: @settings.zoom
            @map = new ol.Map
                target: @element
                layers: [
                    new ol.layer.Tile
                        source: new ol.source.MapQuest
                            layer: 'osm'
                ]
                view: @mapView

            if @settings.address
                geoLib.geocode(@settings.address).then (addr) =>
                    coords = (parseFloat(coord) for coord in [addr.lon, addr.lat])
                    boundingbox = (parseFloat(coord) for coord in [addr.boundingbox[2], addr.boundingbox[0], addr.boundingbox[3], addr.boundingbox[1]])

                    console.debug "Address coords: lon=#{ coords[0] }, lat=#{ coords[1] }"

                    newCoords = ol.proj.transform(coords, @epsg4326, @mapView.getProjection())
                    newBoundingbox = ol.proj.transformExtent(boundingbox, @epsg4326, @mapView.getProjection())

                    console.debug newBoundingbox

                    if @settings.marker and @settings.marker != 'false'
                        if @settings.marker == 'osm'
                            markerUrl = addr.icon ? @settings.markerIcon
                        else
                            markerUrl = if @settings.marker != 'true' then @settings.marker else @settings.markerIcon
                        feature = new ol.Feature($.extend (
                            geometry: new ol.geom.Point(newCoords)
                            name: @settings.address
                            displayName: addr.display_name
                        ), addr.extratags)

                        markerStyle = new ol.style.Style
                            image: new ol.style.Icon
                                anchor: [0.5, 1]
                                anchorXUnits: 'fraction'
                                anchorYUnits: 'fraction'
                                opacity: 0.75
                                src: markerUrl
                        feature.setStyle markerStyle
                        markerSource = new ol.source.Vector features: [feature]
                        markerLayer = new ol.layer.Vector
                            source: markerSource

                        @map.addLayer markerLayer

                        popupElement = $('<div>').appendTo(@$element)
                        popup = new ol.Overlay
                            element: popupElement
                            positioning: 'bottom-center'
                            stopEvent: false
                        @map.addOverlay popup

                        @map.on 'click', (evt) =>
                            feature = @map.forEachFeatureAtPixel evt.pixel, (feature, layer) -> feature

                            if feature
                                popup.setPosition evt.coordinate
                                popupElement.popover
                                    placement: 'top'
                                    html: true
                                    container: 'body'
                                    title: "<div style='overflow:hidden;text-overflow:ellipsis;white-space:nowrap'>#{ feature.get 'name' }</div>"
                                    content: feature.get 'displayName'
                                popupElement.popover 'show'
                            else
                                popupElement.popover 'destroy'

                            return

                        @map.on 'pointermove', (evt) =>
                            if evt.dragging
                                popupElement.popover 'destroy'
                            else
                                pixel = @map.getEventPixel evt.originalEvent
                                hit = @map.hasFeatureAtPixel pixel
                                @map.getTarget().style.cursor = if hit then 'pointer' else ''

                            return

                    @mapView.setCenter newCoords
                    @mapView.fit newBoundingbox, @map.getSize()
            return

        addJsonLayer: (url) ->
            if not @map or not @mapView
                return
            console.log "Adding json layer for '#{ url }'"
            jsonLayer = new ol.layer.Vector
                source: new ol.source.Vector
                    url: url
                    format: new ol.format.GeoJSON
                        defaultProjection: 'EPSG:4326'
                    projection: 'EPSG:3857'
                name: url
            @map.addLayer jsonLayer
            return

    exported =
        initHtml: ->
            $this = $(this)
            jqol = new JqOpenLayers(this, { })
            $this.data 'JqOpenLayers', jqol
            jqol.initMapFromHtml()
            $this

        init: (options) ->
            $this = $(this)
            dataOptions =
                address: $this.attr 'data-address'
                coords: $this.attr 'data-coords'
                zoom: parseInt $this.attr('data-zoom'), 10
                marker: $this.attr 'data-marker'
                markerIcon: $this.attr 'data-marker-icon'
            settings = $.extend dataOptions, options
            jqol = new JqOpenLayers(this, settings)
            $this.data 'JqOpenLayers', jqol
            jqol.initMap()
            $this
        addJsonLayer: (url) ->
            $this = $(this)
            jqol = $this.data 'JqOpenLayers'
            if jqol
                jqol.addJsonLayer url
            $this

    $.fn.jqOpenLayers = (options) ->
        _arguments = arguments
        console.log "(#{ options }): Waiting for ol..."
        geoLib.loadOpenLayers().then =>
            console.log "(#{ options }): ol should be available now!"
            @each ->
                if exported[options]
                    exported[options].apply this, Array.prototype.slice.call(_arguments, 1)
                else if typeof options is 'object' or not options
                    exported['init'].apply this, options
                else
                    $.error "The method '#{ options }' does not exist on jQuery.jqOpenLayers"

    $.fn.jqOpenLayers.defaults =
        address: null
        coords: [0, 0]
        zoom: 1
        marker: null
        markerIcon: 'http://openlayers.org/en/v3.8.2/examples/data/icon.png'

    return
