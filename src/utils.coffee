define ['jquery', 'Q', 'ol3'], ($, Q, ol) -> class Utils
    geocode: (query) ->
        deferred = Q.defer()
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
        deferred.promise

