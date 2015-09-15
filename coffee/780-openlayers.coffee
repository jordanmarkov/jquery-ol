do ->
    exported =
        init: ->
            $this = $(this)
            jqol = new OlParser()
            $this.data 'JqOpenLayers', jqol
            jqol.parseMap $this
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
