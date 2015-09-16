do ->
    exported =
        init: (_options) ->
            options = $.extend { }, $.fn.jqOpenLayers.defaults, _options
            $this = $(this)
            jqol = new OlParser()
            $this.data 'JqOpenLayers', jqol
            jqol.parseMap $this, options
            $this

    $.fn.jqOpenLayers = (options) ->
        _arguments = arguments
        #console.log "(#{ options }): Waiting for ol..."
        geoLib.loadOpenLayers().then =>
            #console.log "(#{ options }): ol should be available now!"
            @each ->
                if exported[options]
                    exported[options].apply this, Array.prototype.slice.call(_arguments, 1)
                else if typeof options is 'object' or not options
                    exported['init'].apply this, options
                else
                    $.error "The method '#{ options }' does not exist on jQuery.jqOpenLayers"

    $.fn.jqOpenLayers.defaults =
        projection: null
        enablePopups: false
        enableTooltips: false
        onLayerAdded: null
        onLayerLoaded: null

    return
