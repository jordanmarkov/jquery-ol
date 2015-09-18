class OlInteractions
    _map = null
    _deafultHoverOptions =
        onTooltipAvailable: ''
        onPopupAvailabe: 'pointer'

    constructor: (map) ->
        _map = map
        return

    dragCursor: ->
        _map.on 'moveend', (e) ->
            $(_map.getTarget()).css cursor: ''
            return

        _map.on 'pointerdrag', (e) ->
            $(_map.getTarget()).css cursor: 'move'
            return

        _map.on 'pointermove', (e) ->
            if e.dragging
                $(_map.getTarget()).css cursor: 'move'
            return

        return

    hoverCursor: (_options) ->
        options = $.extend {}, _deafultHoverOptions, _options
        _map.on 'pointermove', (e) ->
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) -> feature
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
        return

    popups: ->
        $popupElement = $('<div>').appendTo($(_map.getTarget()))
        popupOverlay = new ol.Overlay
            element: $popupElement[0]
            positioning: 'bottom-center'
            stopEvent: false

        _map.addOverlay popupOverlay

        _map.on 'click', (e) ->
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) -> feature
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
        return

    _getFeatureTooltipText = (feature) ->
        if !feature.get('_tooltipFun')
            # tooltip function not cached, we have three options now
            tooltipTemplate = feature.get('tooltip')
            if tooltipTemplate.startsWith('prop:')
                # we need to get a property value or empty string if this property does not exist
                propName = tooltipTemplate[5...]
                feature.set '_tooltipFun', (f) -> f.get(propName) or ''
            else if tooltipTemplate.startsWith('fn:')
                # we'll execute a function to get the value
                # TODO: make sure the user explicitly enables this feature. It's vulnerable to XSS in the
                # general case
                fnText = tooltipTemplate[3...]
                fn = eval("(#{ fnText })")
                feature.set '_tooltipFun', (f) -> fn.call(f, f)
            else
                # none of the above. Just use the provided text for the popup.
                feature.set '_tooltipFun', (f) -> tooltipTemplate

        # now we have the cached function, return the taxt
        feature.get('_tooltipFun').call(feature, feature)

    tooltips: ->
        # not using overlay for the popup because it's not really working. The popup covers
        # the feature in some cases.
        $tooltipElement = $('<div>').appendTo($(_map.getTarget()))
        $tooltipElement.css
            position: 'absolute'
        $tooltipElement.tooltip
            animation: false # this is important, animation messes the logic here
            delay:
                show: 0
                hide: 0
            html: true
            placement: 'top'
            trigger: 'manual'

        # this'll contain the feature with currently shown popup
        tooltipShown = null

        _map.on 'pointermove', (e) ->
            # not sure how this pixel is different from the e.pixel, but thats how it's done
            # half the time in OL examples
            pixel = _map.getEventPixel e.originalEvent
            feature = _map.forEachFeatureAtPixel pixel, (feature, layer) -> feature

            # TODO: it would be nice to know if a popup is active and disable the tooltip
            if not feature
                $tooltipElement.tooltip 'destroy'
                tooltipShown = null
            else
                tooltipText = _getFeatureTooltipText(feature)
                if tooltipText
                    # move the tooltip above the mouse pointer
                    $tooltipElement.css
                        left: "#{ pixel[0] }px"
                        top: "#{ pixel[1] - 15 }px" # offset the tooltip above the feature

                    # change the title
                    $tooltipElement.attr
                        'data-original-title': tooltipText
                    $tooltipElement.tooltip 'fixTitle'
                    # update the new tooltip
                    $tooltipElement.tooltip 'show'
                    tooltipShown = feature
                else
                    $tooltipElement.tooltip 'hide'
                    tooltipShown = null
            return
        return
