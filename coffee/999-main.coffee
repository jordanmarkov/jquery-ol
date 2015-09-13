# CoffeeScript
$ ->
    $('[data-toggle="openlayers"]').jqOpenLayers 'initHtml', {}

    #console.log "Making a dynamic request"
    #$.ajax
    #    url: 'asset://res/dynamic/track'
    #    dataType: "json"
    #    success: (data, textStatus, jqXHR) ->
    #        dataStr = JSON.stringify data
    #        console.log "Received: #{ dataStr }"
    #    error: (jqXHR, textStatus, errorThrown) ->
    #        console.error "Cannot receive geojson: #{ errorThrown }"

    #console.log "Registering for addLayer"
    #setTimeout (->
    #    console.log "Adding layer..."
    #    $('[data-toggle="openlayers"]').jqOpenLayers 'addJsonLayer', 'asset://res/dynamic/track'
    #), 500
