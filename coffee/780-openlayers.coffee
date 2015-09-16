do ->
    exported =
        init: (_options) ->
            options = $.extend { }, $.fn.jqOpenLayers.defaults, _options
            $this = $(this)
            jqol = new OlParser()
            $this.data 'JqOpenLayers', jqol
            jqol.parseMap $this, options
            $this

        getLayers: ->
            $this = $(this)
            jqol = $this.data 'JqOpenLayers'
            jqol.getLayers()

        getVectorLayers: ->
            $this = $(this)
            jqol = $this.data 'JqOpenLayers'
            jqol.getVectorLayers()

    $.fn.jqOpenLayers = (options) ->
        _arguments = arguments
        deferred = $.Deferred()
        geoLib.loadOpenLayers().then =>
            #console.log "(#{ options }): ol should be available now!"
            @each ->
                if exported[options]
                    deferred.resolve(exported[options].apply this, Array.prototype.slice.call(_arguments, 1))
                else if typeof options is 'object' or not options
                    deferred.resolve(exported['init'].apply this, options)
                else
                    $.error "The method '#{ options }' does not exist on jQuery.jqOpenLayers"
                    deferred.reject()
        deferred

    $.fn.jqOpenLayers.defaults =
        projection: null
        enablePopups: false
        enableTooltips: false
        onLayerAdded: null
        onLayerLoaded: null

    return
