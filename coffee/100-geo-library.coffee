class GeoLib
    _olLoading = false

    constructor: ->

    loadCss: (url) ->
        if $("link[href='#{ url }']").length == 0
            link = $ '<link>',
                rel: 'stylesheet'
                type: 'text/css'
            $head.append link
            link.attr href: url
        return

    loadJs: (url) ->
        deferred = $.Deferred()
        if @_olLoading
            # wait for loading to complete and then resolve
            timer = setInterval (=>
                if not @_olLoading
                    #console.log "stop waiting..."
                    clearInterval timer
                    deferred.resolve(this)
                return
            ), 10
        else
            @_olLoading = true
            $.ajax
                url: url
                dataType: "script"
                cache: true
                success: (data, textStatus, jqxhr) =>
                    @_olLoading = false
                    deferred.resolve(this)
        deferred

    loadOpenLayers: (jsUrl, cssUrl) ->
        deferred = $.Deferred()
        if not ol?
            jsUrl ?= 'http://openlayers.org/en/v3.8.2/build/ol-debug.js'
            cssUrl ?= 'http://openlayers.org/en/v3.8.2/css/ol.css'

            setTimeout (=>
                @loadJs(jsUrl).done ->
                    #console.log "OpenLayers loaded #{ ol }"
                    deferred.resolve(ol)
                @loadCss cssUrl
            ), 0
        else
            #console.log "OpenLayers already loaded"
            deferred.resolve(ol)

        deferred


    geocode: (query) ->
        deferred = $.Deferred()
        $.ajax
            url: 'http://nominatim.openstreetmap.org/search/'
            data:
                q: query
                format: 'jsonv2'
                limit: 1
                extratags: 1
            dataType: 'json'
            success: (data, textStatus, jqXHR) ->
                if data and data.length > 0
                    console.info "Address '#{ query }' found"
                    deferred.resolve data[0]
                else
                    console.warn "Address '#{ query }' not found"
                    deferred.reject null
            error: (jqXHR, textStatus, errorThrown) ->
                console.error  "ajax error for '#{ query }': #{ textStatus }, #{ errorThrown }"
                deferred.reject textStatus
        deferred

    createGUID: ->
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
            r = Math.random() * 16 | 0
            v = if c == 'x' then r else (r & 0x3 | 0x8)
            v.toString(16)
        ).toUpperCase()

geoLib = new GeoLib()
$.fn.setUniqueId = ->
    if this.attr('id')
        this
    else
        guid = ''
        while not guid
            _guid = geoLib.createGUID()
            if $("##{ _guid }").length == 0
                this.attr('id', _guid)
                guid = _guid
        this
