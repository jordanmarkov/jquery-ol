# Funtions exported by the jQuery plugin
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
    if exported[options] and exported[options] != 'init'
        if $(this).length != 1
            $.error "Cannot invoke the method '#{ options }' on multiple elements"
        else
            return exported[options].apply this, Array.prototype.slice.call(_arguments, 1)

    geoLib.loadOpenLayers().then =>
        @each ->
            if typeof options is 'object' or not options or (exported[options] and exported[options] == 'init')
                exported.init.apply this, options
            else
                $.error "The method '#{ options }' does not exist on jQuery.jqOpenLayers"
    return $(this)

$.fn.jqOpenLayers.defaults =
    projection: null
    enablePopups: false
    enableTooltips: false
    onLayerAdded: null
    onLayerLoaded: null

