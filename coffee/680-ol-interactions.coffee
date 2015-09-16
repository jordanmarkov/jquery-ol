class OlInteractions
    _map = null
    _deafultHoverOptions =
        onTooltipAvailable: ''
        onPopupAvailabe: 'pointer'

    constructor: (map) ->
        _map = map

    dragCursor: ->
        _map.on 'moveend', (e) =>
            $(_map.getTarget()).css cursor: ''
            return

        _map.on 'pointerdrag', (e) =>
            $(_map.getTarget()).css cursor: 'move'
            return

        _map.on 'pointermove', (e) =>
            if e.dragging
                $(_map.getTarget()).css cursor: 'move'

    hoverCursor: (_options) ->
        options = $.extend {}, _deafultHoverOptions, _options
        _map.on 'pointermove', (e) =>
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) => feature
            if feature
                if options.onTooltipAvailable and feature.get('tooltip')
                    $(_map.getTarget()).css cursor: options.onTooltipAvailable
                else if options.onPopupAvailabe and feature.get('href')
                    $(_map.getTarget()).css cursor: options.onPopupAvailabe
                else
                    $(_map.getTarget()).css cursor: ''
            else
                $(_map.getTarget()).css cursor: ''
            return

    popups: ->
        $popupElement = $('<div>').appendTo($(_map.getTarget()))
        popupOverlay = new ol.Overlay
            element: $popupElement[0]
            positioning: 'bottom-center'
            stopEvent: false

        _map.addOverlay popupOverlay

        _map.on 'click', (e) =>
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) => feature
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
                            html: true
                            container: 'body'
                            content: htmlData
                            title: title
                        $popupElement.popover 'show'
                    error: (jqXHR, textStatus, errorThrown) ->
                        $popupElement.popover 'destroy'
            else
                $popupElement.popover 'destroy'
            return

    tooltips: ->
        $tooltipElement = $('<div>').appendTo($(_map.getTarget()))
        tooltipOverlay = new ol.Overlay
            element: $tooltipElement[0]
            positioning: 'top-center'
            stopEvent: false

        _map.addOverlay tooltipOverlay

        tooltipShown = null
        _map.on 'pointermove', (e) =>
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) => feature
            if not feature
                if tooltipShown
                    $tooltipElement.tooltip 'destroy'
                    tooltipShown = null
                return

            tooltip = feature.get('tooltip')
            tooltipFn = feature.get('_tooltipFun')

            if not tooltip
                if tooltipShown
                    $tooltipElement.tooltip 'destroy'
                    tooltipShown = null
                return

            if tooltipShown != feature
                geom = feature.getGeometry()
                coords = if geom.getType() == 'Point' then geom.getCoordinates() else e.coordinate
                tooltipOverlay.setPosition coords
                if feature.get('_tooltipFun')
                    tooltipContent = feature.get('_tooltipFun').call(feature, feature)
                else
                    tooltipTemplate = feature.get('tooltip')
                    if tooltipTemplate.startsWith('prop:')
                        propName = tooltipTemplate[5...]
                        feature.set '_tooltipFun', (f) -> f.get(propName)
                    else if tooltipTemplate.startsWith('fn:')
                        fnText = tooltipTemplate[3...]
                        fn = eval("(#{ fnText })")
                        feature.set '_tooltipFun', (f) -> fn.call(f, f)
                    else
                        feature.set '_tooltipFun', (f) -> tooltipTemplate

                    tooltipContent = feature.get('_tooltipFun').call(feature, feature)

                changeTooltop = ->
                    $tooltipElement.tooltip
                        trigger: 'manual'
                        placement: 'top'
                        html: true
                        container: 'body'
                        title: tooltipContent
                    $tooltipElement.tooltip 'show'
                if tooltipShown
                    $tooltipElement.one 'hidden.bs.tooltip', =>
                        $tooltipElement.tooltip 'destroy'
                        setTimeout changeTooltop, 200
                    $tooltipElement.tooltip 'hide'
                else
                    changeTooltop()
                tooltipShown = feature
            return
