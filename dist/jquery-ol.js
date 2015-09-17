(function() {
  var $, $body, $document, $head, $html, $window, GeoLib, OlInteractions, OlParser, OlStyleParser, base, base1, base2, base3, base4, geoLib, root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  $ = jQuery;

  $window = $(window);

  $document = $(document);

  $html = $('html');

  $head = $('head');

  $body = $('body');

  if ((base = String.prototype).startsWith == null) {
    base.startsWith = function(s) {
      return this.slice(0, s.length) === s;
    };
  }

  if ((base1 = String.prototype).endsWith == null) {
    base1.endsWith = function(s) {
      return s === '' || this.slice(-s.length) === s;
    };
  }

  if ((base2 = String.prototype).trim == null) {
    base2.trim = function() {
      return this.replace(/^\s+|\s+$/g, '');
    };
  }

  if ((base3 = Array.prototype).any == null) {
    base3.any = function(f) {
      var i, len, x;
      for (i = 0, len = this.length; i < len; i++) {
        x = this[i];
        if (f(x)) {
          return true;
        }
      }
      return false;
    };
  }

  if ((base4 = Array.prototype).all == null) {
    base4.all = function(f) {
      var i, len, x;
      for (i = 0, len = this.length; i < len; i++) {
        x = this[i];
        if (!f(x)) {
          return false;
        }
      }
      return true;
    };
  }

  GeoLib = (function() {
    var _olLoading;

    _olLoading = false;

    function GeoLib() {}

    GeoLib.prototype.loadCss = function(url) {
      var link;
      if ($("link[href='" + url + "']").length === 0) {
        link = $('<link>', {
          rel: 'stylesheet',
          type: 'text/css'
        });
        $head.append(link);
        link.attr({
          href: url
        });
      }
    };

    GeoLib.prototype.loadJs = function(url) {
      var deferred, timer;
      deferred = $.Deferred();
      if (this._olLoading) {
        timer = setInterval(((function(_this) {
          return function() {
            if (!_this._olLoading) {
              clearInterval(timer);
              deferred.resolve(_this);
            }
          };
        })(this)), 10);
      } else {
        this._olLoading = true;
        $.ajax({
          url: url,
          dataType: "script",
          cache: true,
          success: (function(_this) {
            return function(data, textStatus, jqxhr) {
              _this._olLoading = false;
              return deferred.resolve(_this);
            };
          })(this)
        });
      }
      return deferred;
    };

    GeoLib.prototype.loadOpenLayers = function(jsUrl, cssUrl) {
      var deferred;
      deferred = $.Deferred();
      if (typeof ol === "undefined" || ol === null) {
        if (jsUrl == null) {
          jsUrl = 'http://openlayers.org/en/v3.8.2/build/ol-debug.js';
        }
        if (cssUrl == null) {
          cssUrl = 'http://openlayers.org/en/v3.8.2/css/ol.css';
        }
        setTimeout(((function(_this) {
          return function() {
            _this.loadJs(jsUrl).done(function() {
              return deferred.resolve(ol);
            });
            return _this.loadCss(cssUrl);
          };
        })(this)), 0);
      } else {
        deferred.resolve(ol);
      }
      return deferred;
    };

    GeoLib.prototype.geocode = function(query) {
      var deferred;
      deferred = $.Deferred();
      $.ajax({
        url: 'http://nominatim.openstreetmap.org/search/',
        data: {
          q: query,
          format: 'jsonv2',
          limit: 1,
          extratags: 1
        },
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          if (data && data.length > 0) {
            console.info("Address '" + query + "' found");
            return deferred.resolve(data[0]);
          } else {
            console.warn("Address '" + query + "' not found");
            return deferred.reject(null);
          }
        },
        error: function(jqXHR, textStatus, errorThrown) {
          console.error("ajax error for '" + query + "': " + textStatus + ", " + errorThrown);
          return deferred.reject(textStatus);
        }
      });
      return deferred;
    };

    GeoLib.prototype.createGUID = function() {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r, v;
        r = Math.random() * 16 | 0;
        v = c === 'x' ? r : r & 0x3 | 0x8;
        return v.toString(16);
      }).toUpperCase();
    };

    return GeoLib;

  })();

  geoLib = new GeoLib();

  $.fn.setUniqueId = function() {
    var _guid, guid;
    if (this.attr('id')) {
      return this;
    } else {
      guid = '';
      while (!guid) {
        _guid = geoLib.createGUID();
        if ($("#" + _guid).length === 0) {
          this.attr('id', _guid);
          guid = _guid;
        }
      }
      return this;
    }
  };

  OlInteractions = (function() {
    var _deafultHoverOptions, _map;

    _map = null;

    _deafultHoverOptions = {
      onTooltipAvailable: '',
      onPopupAvailabe: 'pointer'
    };

    function OlInteractions(map) {
      _map = map;
      return;
    }

    OlInteractions.prototype.dragCursor = function() {
      _map.on('moveend', (function(_this) {
        return function(e) {
          $(_map.getTarget()).css({
            cursor: ''
          });
        };
      })(this));
      _map.on('pointerdrag', (function(_this) {
        return function(e) {
          $(_map.getTarget()).css({
            cursor: 'move'
          });
        };
      })(this));
      _map.on('pointermove', (function(_this) {
        return function(e) {
          if (e.dragging) {
            $(_map.getTarget()).css({
              cursor: 'move'
            });
          }
        };
      })(this));
    };

    OlInteractions.prototype.hoverCursor = function(_options) {
      var options;
      options = $.extend({}, _deafultHoverOptions, _options);
      _map.on('pointermove', (function(_this) {
        return function(e) {
          var feature, pixel;
          pixel = _map.getEventPixel(e.originalEvent);
          feature = _map.forEachFeatureAtPixel(pixel, function(feature, layer) {
            return feature;
          });
          if (feature) {
            if (options.onTooltipAvailable && feature.get('tooltip')) {
              $(_map.getTarget()).css({
                cursor: options.onTooltipAvailable
              });
            } else if (options.onPopupAvailabe && feature.get('href')) {
              $(_map.getTarget()).css({
                cursor: options.onPopupAvailabe
              });
            } else {
              $(_map.getTarget()).css({
                cursor: ''
              });
            }
          } else {
            $(_map.getTarget()).css({
              cursor: ''
            });
          }
        };
      })(this));
    };

    OlInteractions.prototype.popups = function() {
      var $popupElement, popupOverlay;
      $popupElement = $('<div>').appendTo($(_map.getTarget()));
      popupOverlay = new ol.Overlay({
        element: $popupElement[0],
        positioning: 'bottom-center',
        stopEvent: false
      });
      _map.addOverlay(popupOverlay);
      _map.on('click', (function(_this) {
        return function(e) {
          var feature, pixel;
          pixel = _map.getEventPixel(e.originalEvent);
          feature = _map.forEachFeatureAtPixel(pixel, function(feature, layer) {
            return feature;
          });
          if (feature && feature.get('href')) {
            $.ajax({
              url: feature.get('href'),
              cache: false,
              dataType: 'html',
              success: function(data, textStatus, jqXHR) {
                var htmlData, title;
                htmlData = $.parseHTML(data);
                if (htmlData.length > 1) {
                  htmlData = $('<div>').html(htmlData);
                }
                title = htmlData.children('h1,h2,h3,h4,h5,h6').first();
                if (title) {
                  htmlData.detach('h1:first,h2:first,h3:first,h4:first,h5:first,h6:first');
                }
                popupOverlay.setPosition(e.coordinate);
                $popupElement.popover({
                  placement: 'top',
                  html: true,
                  container: 'body',
                  content: htmlData,
                  title: title
                });
                return $popupElement.popover('show');
              },
              error: function(jqXHR, textStatus, errorThrown) {
                return $popupElement.popover('destroy');
              }
            });
          } else {
            $popupElement.popover('destroy');
          }
        };
      })(this));
    };

    OlInteractions.prototype.tooltips = function() {
      var $tooltipElement, tooltipOverlay, tooltipShown;
      $tooltipElement = $('<div>').appendTo($(_map.getTarget()));
      tooltipOverlay = new ol.Overlay({
        element: $tooltipElement[0],
        positioning: 'top-center',
        stopEvent: false
      });
      _map.addOverlay(tooltipOverlay);
      tooltipShown = null;
      _map.on('pointermove', (function(_this) {
        return function(e) {
          var changeTooltop, coords, feature, fn, fnText, geom, pixel, propName, tooltip, tooltipContent, tooltipFn, tooltipTemplate;
          pixel = _map.getEventPixel(e.originalEvent);
          feature = _map.forEachFeatureAtPixel(pixel, function(feature, layer) {
            return feature;
          });
          if (!feature) {
            if (tooltipShown) {
              $tooltipElement.tooltip('destroy');
              tooltipShown = null;
            }
            return;
          }
          tooltip = feature.get('tooltip');
          tooltipFn = feature.get('_tooltipFun');
          if (!tooltip) {
            if (tooltipShown) {
              $tooltipElement.tooltip('destroy');
              tooltipShown = null;
            }
            return;
          }
          if (tooltipShown !== feature) {
            geom = feature.getGeometry();
            coords = geom.getType() === 'Point' ? geom.getCoordinates() : e.coordinate;
            tooltipOverlay.setPosition(coords);
            if (feature.get('_tooltipFun')) {
              tooltipContent = feature.get('_tooltipFun').call(feature, feature);
            } else {
              tooltipTemplate = feature.get('tooltip');
              if (tooltipTemplate.startsWith('prop:')) {
                propName = tooltipTemplate.slice(5);
                feature.set('_tooltipFun', function(f) {
                  return f.get(propName);
                });
              } else if (tooltipTemplate.startsWith('fn:')) {
                fnText = tooltipTemplate.slice(3);
                fn = eval("(" + fnText + ")");
                feature.set('_tooltipFun', function(f) {
                  return fn.call(f, f);
                });
              } else {
                feature.set('_tooltipFun', function(f) {
                  return tooltipTemplate;
                });
              }
              tooltipContent = feature.get('_tooltipFun').call(feature, feature);
            }
            changeTooltop = function() {
              $tooltipElement.tooltip({
                trigger: 'manual',
                placement: 'top',
                html: true,
                container: 'body',
                title: tooltipContent
              });
              return $tooltipElement.tooltip('show');
            };
            if (tooltipShown) {
              $tooltipElement.one('hidden.bs.tooltip', function() {
                $tooltipElement.tooltip('destroy');
                return setTimeout(changeTooltop, 200);
              });
              $tooltipElement.tooltip('hide');
            } else {
              changeTooltop();
            }
            tooltipShown = feature;
          }
        };
      })(this));
    };

    return OlInteractions;

  })();

  OlStyleParser = (function() {
    var _styleCache;

    function OlStyleParser() {}

    _styleCache = {};

    OlStyleParser.prototype._parseFillStyle = function($element) {
      if (($element == null) || $element.length === 0) {

      } else {
        return new ol.style.Fill({
          color: $element.attr('color') || (function() {
            throw "Fill color is required";
          })()
        });
      }
    };

    OlStyleParser.prototype._parseStrokeStyle = function($element) {
      var properties;
      if (($element == null) || $element.length === 0) {

      } else {
        properties = {
          color: $element.attr('color') || (function() {
            throw "Stroke color is required";
          })(),
          width: parseFloat($element.attr('width') || (function() {
            throw "Stroke width is required";
          })())
        };
        $element.children('ol-property').each(function() {
          var key, p, val;
          key = $(this).attr('name');
          val = $(this).text();
          val = (function() {
            var i, len, ref, results;
            switch (key) {
              case 'miterLimit':
                return parseFloat(val);
              case 'lineCap':
                if (val === 'butt' || val === 'round' || val === 'square') {
                  return val;
                } else {
                  throw "Usupported lineCap value: '" + val + "'. Supported are 'butt', 'round' or 'square'.";
                }
              case 'lineJoin':
                if (val === 'bevel' || val === 'round' || val === 'miter') {
                  return val;
                } else {
                  throw "Usupported lineJoin value: '" + val + "'. Supported are 'bevel', 'round' or 'miter'.";
                }
              case 'lineDash':
                ref = val.split(',');
                results = [];
                for (i = 0, len = ref.length; i < len; i++) {
                  p = ref[i];
                  results.push(parseFloat(p));
                }
                return results;
              default:
                throw "Usupported stroke property: '" + key + "'";
            }
          })();
          return properties[key] = val;
        });
        return new ol.style.Stroke(properties);
      }
    };

    OlStyleParser.prototype._getCircleProperties = function($element) {
      var properties;
      properties = {
        radius: parseFloat($element.attr('radius')) || (function() {
          throw "Radius is required";
        })(),
        snaptopixel: $element.attr('snaptopixel') !== 'false',
        fill: this._parseFillStyle($element.children('ol-fill')),
        stroke: this._parseStrokeStyle($element.children('ol-stroke'))
      };
      return properties;
    };

    OlStyleParser.prototype._getIconProperties = function($element) {
      var properties;
      properties = {
        src: $element.attr('src') || (function() {
          throw "Icon source is required";
        })(),
        snaptopixel: $element.attr('snaptopixel') !== 'false'
      };
      $element.children('ol-property').each(function() {
        var key, val, x;
        key = $(this).attr('name');
        val = $(this).text();
        val = (function() {
          var i, j, k, l, len, len1, len2, len3, ref, ref1, ref2, ref3, results, results1, results2, results3;
          switch (key) {
            case 'opacity' || 'scale' || 'rotation':
              return parseFloat(val);
            case 'anchor':
              ref = val.split(',');
              results = [];
              for (i = 0, len = ref.length; i < len; i++) {
                x = ref[i];
                results.push(parseFloat(x));
              }
              return results;
            case 'offset':
              ref1 = val.split(',');
              results1 = [];
              for (j = 0, len1 = ref1.length; j < len1; j++) {
                x = ref1[j];
                results1.push(parseFloat(x));
              }
              return results1;
            case 'rotateWithView':
              return val !== 'false';
            case 'size':
              ref2 = val.split(',');
              results2 = [];
              for (k = 0, len2 = ref2.length; k < len2; k++) {
                x = ref2[k];
                results2.push(parseFloat(x));
              }
              return results2;
            case 'imgSize':
              ref3 = val.split(',');
              results3 = [];
              for (l = 0, len3 = ref3.length; l < len3; l++) {
                x = ref3[l];
                results3.push(parseFloat(x));
              }
              return results3;
            case 'anchorOrigin':
              return val;
            case 'anchorXUnits':
              return val;
            case 'anchorYUnits':
              return val;
            case 'crossOrigin':
              return val;
            case 'offsetOrigin':
              return val;
            default:
              throw "Usupported icon property: '" + key + "'";
          }
        })();
        return properties[key] = val;
      });
      return properties;
    };

    OlStyleParser.prototype._getRegularShapeProperties = function($element) {
      var properties;
      properties = {
        radius: parseFloat($element.attr('radius')) || (function() {
          throw "Radius is required";
        })(),
        snaptopixel: $element.attr('snaptopixel') !== 'false',
        fill: this._parseFillStyle($element.children('ol-fill')),
        stroke: this._parseStrokeStyle($element.children('ol-stroke'))
      };
      $element.children('ol-property').each(function() {
        var key, val;
        key = $(this).attr('name');
        val = $(this).text();
        val = (function() {
          switch (key) {
            case 'points':
              return parseFloat(val);
            case 'radius1':
              return parseFloat(val);
            case 'radius2':
              return parseFloat(val);
            case 'angle':
              return parseFloat(val);
            case 'rotation':
              return parseFloat(val);
            default:
              throw "Usupported regular shape property: '" + key + "'";
          }
        })();
        return properties[key] = val;
      });
      return properties;
    };

    OlStyleParser.prototype._parseImageStyle = function($element) {
      if (($element == null) || $element.length === 0) {

      } else {
        if ($element.length !== 1) {
          throw "Expected exactly 1 image style, " + $element.length + " given.";
        }
        switch ($element.attr('type')) {
          case 'circle':
            return new ol.style.Circle(this._getCircleProperties($element));
          case 'icon':
            return new ol.style.Icon(this._getIconProperties($element));
          case 'regular-shape':
            return new ol.style.RegularShape(this._getRegularShapeProperties($element));
          default:
            throw "Usupported image type. Supported are 'circle', 'icon' or 'regular-shape'.";
        }
      }
    };

    OlStyleParser.prototype._parseSymbolizer = function($element) {
      return new ol.style.Style({
        image: this._parseImageStyle($element.children('ol-image')),
        stroke: this._parseStrokeStyle($element.children('ol-stroke')),
        fill: this._parseFillStyle($element.children('ol-fill'))
      });
    };

    OlStyleParser.prototype._parseZoomStyle = function($element) {
      var predicate;
      predicate = (function() {
        switch (false) {
          case !$element.attr('lt'):
            return function(zoom) {
              return zoom < parseFloat($element.attr('lt'));
            };
          case !$element.attr('lte'):
            return function(zoom) {
              return zoom <= parseFloat($element.attr('lte'));
            };
          case !$element.attr('gt'):
            return function(zoom) {
              return zoom > parseFloat($element.attr('gt'));
            };
          case !$element.attr('gte'):
            return function(zoom) {
              return zoom >= parseFloat($element.attr('gte'));
            };
          case !$element.attr('eq'):
            return function(zoom) {
              return zoom === parseFloat($element.attr('eq'));
            };
          case !$element.attr('ne'):
            return function(zoom) {
              return zoom !== parseFloat($element.attr('ne'));
            };
          default:
            throw "None of the supported operators found: 'lt', 'lte', 'gt', 'gte', 'eq' or 'ne'.";
        }
      })();
      return {
        predicate: predicate,
        style: this._parseSymbolizer($element)
      };
    };

    OlStyleParser.prototype._parseStyle = function($element) {
      var symbolizers;
      symbolizers = [];
      $element.children('ol-resolution').each((function(_this) {
        return function(idx, val) {
          return symbolizers.push(_this._parseZoomStyle($(val)));
        };
      })(this));
      symbolizers.push({
        predicate: function(zoom) {
          return true;
        },
        style: this._parseSymbolizer($element)
      });
      return (function(_this) {
        return function(feature, resolution) {
          var style, sym;
          style = (function() {
            var i, len, results;
            results = [];
            for (i = 0, len = symbolizers.length; i < len; i++) {
              sym = symbolizers[i];
              if (sym.predicate(resolution)) {
                results.push(sym.style);
              }
            }
            return results;
          })();
          return style.slice(0, 1);
        };
      })(this);
    };

    OlStyleParser.prototype.parseStyles = function($element) {
      return $element.children('ol-style').each((function(_this) {
        return function(idx, styleElement) {
          var $this, name;
          $this = $(styleElement);
          name = $this.attr('name') || (function() {
            throw "Style name is required";
          })();
          _styleCache[name] = _this._parseStyle($this);
        };
      })(this));
    };

    OlStyleParser.prototype.getStyle = function(name) {
      if (name in _styleCache) {
        return _styleCache[name];
      } else {
        throw "Unknown style name: '" + name + "'";
      }
    };

    return OlStyleParser;

  })();

  OlParser = (function() {
    var _configProjection, _layers, _map, _mapProjection, _styleParser;

    function OlParser() {}

    _styleParser = new OlStyleParser();

    _mapProjection = 'EPSG:3857';

    _configProjection = 'EPSG:4326';

    _map = null;

    _layers = [];

    OlParser.prototype._addLayer = function(layer) {
      return _layers.push(layer);
    };

    OlParser.prototype._isDomNode = function(obj) {
      if (typeof Node === 'object') {
        return obj instanceof Node;
      } else {
        return (obj != null) && typeof obj === 'object' && typeof obj.nodeType === "number" && typeof obj.nodeName === "string";
      }
    };

    OlParser.prototype._isDomElement = function(obj) {
      if (typeof HTMLElement === "object") {
        return obj instanceof HTMLElement;
      } else {
        return (obj != null) && typeof obj === 'object' && obj.nodeType === 1 && typeof obj.nodeName === "string";
      }
    };

    OlParser.prototype._parseFixedStrategy = function($element) {
      var bboxCP, bboxMP, coord;
      bboxCP = (function() {
        var i, len, ref, results;
        ref = $element.text().split(',');
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          coord = ref[i];
          results.push(parseFloat(coord.trim()));
        }
        return results;
      })();
      bboxMP = ol.proj.transformExtent(bboxCP, _configProjection, _mapProjection);
      return function() {
        return [bboxMP];
      };
    };

    OlParser.prototype._parseVectorStrategy = function($element) {
      var $strategyElement, $this;
      $strategyElement = $element.children('ol-strategy');
      if ($strategyElement.length > 1) {
        throw "Expected 0 or 1 strategies, " + $strategyElement.length + " given.";
      }
      $this = $strategyElement;
      if ($this.length === 0 || $this.attr('type') === 'all') {
        return ol.loadingstrategy.all;
      } else {
        switch ($this.attr('type')) {
          case 'bbox':
            return ol.loadingstrategy.bbox;
          case 'fixed':
            return this._parseFixedStrategy($this);
          default:
            throw "Usupported strategy type: '" + ($this.attr('type')) + "'";
        }
      }
    };

    OlParser.prototype._parseGeoJsonSourceProperties = function($element) {
      var properties;
      properties = {};
      $element.children('ol-property').each(function() {
        var key, val;
        key = $(this).attr('name');
        val = $(this).text();
        if (!key) {
          throw "Property name cannot be empty in source ol-property";
        }
        if (properties[key] != null) {
          throw "Property name cannot be duplicated in source ol-property";
        }
        return properties[key] = val;
      });
      return properties;
    };

    OlParser.prototype._parseGeoJsonSource = function($element) {
      var format, jsonContent, loader, refreshInterval, source, strategy, that;
      if ($element.attr('src') == null) {
        jsonContent = $element.text();
        source = new ol.source.Vector({
          features: new ol.format.GeoJSON().readFeatures(JSON.parse(jsonContent), {
            dataProjection: $element.attr('projection') || (function() {
              throw "'projection' is required for GeoJson layer";
            })(),
            featureProjection: _mapProjection
          })
        });
        source.oljq_refresh = (function(_this) {
          return function() {};
        })(this);
        return source;
      } else {
        format = new ol.format.GeoJSON({
          defaultProjection: $element.attr('projection') || (function() {
            throw "'projection' is required for GeoJson layer";
          })()
        });
        that = this;
        loader = function(extent, resolution, projection) {
          var ajaxData, layerSource, projectionString;
          layerSource = this;
          projectionString = projection.getCode();
          extent = extent.any(function(c) {
            return c === Infinity || c === -Infinity;
          }) ? projection.getExtent() : extent;
          ajaxData = $.extend({}, layerSource.getProperties(), {
            srs: projectionString,
            extent: extent.join(','),
            resolution: resolution
          });
          $.ajax({
            url: $element.attr('src'),
            data: ajaxData,
            cache: false,
            dataType: 'json',
            success: function(data, textStatus, jqXHR) {
              var features;
              features = format.readFeatures(data, {
                dataProjection: format.defaultDataProjection,
                featureProjection: _mapProjection
              });
              return layerSource.addFeatures(features);
            },
            error: function(jqXHR, textStatus, errorThrown) {
              return console.error("ajax error for '" + ($element.attr('src')) + "': " + textStatus + ", " + errorThrown);
            }
          });
        };
        strategy = this._parseVectorStrategy($element);
        source = new ol.source.Vector({
          loader: loader,
          strategy: strategy,
          projection: _mapProjection
        });
        source.setProperties(that._parseGeoJsonSourceProperties($element));
        if ($element.attr('refresh') != null) {
          refreshInterval = parseInt($element.attr('refresh'), 10);
          if (refreshInterval > 0) {
            setInterval(((function(_this) {
              return function() {
                var view;
                view = _map.getView();
                return loader.call(source, view.calculateExtent(_map.getSize()), view.getResolution(), view.getProjection());
              };
            })(this)), refreshInterval);
          }
        }
        source.oljq_refresh = (function(_this) {
          return function() {
            var view;
            if (_map == null) {
              return;
            }
            view = _map.getView();
            loader.call(source, view.calculateExtent(_map.getSize()), view.getResolution(), view.getProjection());
          };
        })(this);
        return source;
      }
    };

    OlParser.prototype._parseVectorSource = function($element) {
      var $sourceElement, $this, source;
      $sourceElement = $element.children('ol-source');
      if ($sourceElement.length !== 1) {
        throw "Expected exactly 1 source, " + $sourceElement.length + " given.";
      }
      $this = $sourceElement;
      if ($this.attr('type') !== 'vector') {
        throw "Usupported vector source type: '" + ($this.attr('type')) + "'";
      }
      source = (function() {
        switch ($this.attr('format')) {
          case 'geojson':
            return this._parseGeoJsonSource($this);
          case 'inline':
            return this._parseInlineSource($this);
          default:
            throw "Usupported vector source format type: '" + ($this.attr('format')) + "'";
        }
      }).call(this);
      source.oljq_refresh = (function(_this) {
        return function() {};
      })(this);
      return source;
    };

    OlParser.prototype._parseVectorLayer = function($element) {
      var layerStyleName;
      layerStyleName = $element.attr('style-id');
      return new ol.layer.Vector({
        source: this._parseVectorSource($element),
        name: $element.attr('name'),
        style: _styleParser.getStyle(layerStyleName)
      });
    };

    OlParser.prototype._parseMapQuestSource = function($element) {
      var layerName, source;
      layerName = $element.attr('layer');
      if (layerName !== 'osm' && layerName !== 'sat' && layerName !== 'hyb') {
        throw "Unsupported MapQuest layer: '" + layerName + "'. Valid options are 'osm', 'sat' or 'hyb'.";
      }
      source = new ol.source.MapQuest({
        layer: layerName
      });
      source.oljq_refresh = (function(_this) {
        return function() {};
      })(this);
      return source;
    };

    OlParser.prototype._parseOSMSource = function($element) {
      var source, urlFormat;
      urlFormat = $element.attr('url-format' || void 0);
      source = new ol.source.OSM({
        url: urlFormat
      });
      source.oljq_refresh = (function(_this) {
        return function() {};
      })(this);
      return source;
    };

    OlParser.prototype._parseTileSource = function($element) {
      var $sourceElements, $this, source;
      $sourceElements = $element.children('ol-source');
      if ($sourceElements.length !== 1) {
        throw "Expected exactly 1 source, " + $sourceElements.length + " given.";
      }
      $this = $($sourceElements[0]);
      source = (function() {
        switch ($this.attr('type')) {
          case 'mapQuest':
            return this._parseMapQuestSource($this);
          case 'osm':
            return this._parseOSMSource($this);
          default:
            throw "Usupported tile source type: '" + ($this.attr('type')) + "'";
        }
      }).call(this);
      source.oljq_refresh = (function(_this) {
        return function() {};
      })(this);
      return source;
    };

    OlParser.prototype._parseTileLayer = function($element) {
      return new ol.layer.Tile({
        source: this._parseTileSource($element),
        name: $element.attr('name')
      });
    };

    OlParser.prototype._parseOlLayers = function($element) {
      var layers;
      layers = [];
      $element.children('ol-layer').each((function(_this) {
        return function(idx, olLayerElement) {
          var $this, layer;
          $this = $(olLayerElement);
          layer = (function() {
            switch ($this.attr('type')) {
              case 'vector':
                return this._parseVectorLayer($this);
              case 'tile':
                return this._parseTileLayer($this);
              default:
                throw "Usupported layer type: '" + ($this.attr('type')) + "'";
            }
          }).call(_this);
          layers.push(layer);
          _this._addLayer(layer);
        };
      })(this));
      return layers;
    };

    OlParser.prototype._parseView = function($element) {
      var $this, $viewElements, properties, ref;
      $viewElements = $element.children('ol-view');
      if ($viewElements.length !== 1) {
        throw "Expected exactly 1 view, " + $viewElements.length + " given.";
      }
      $this = $($viewElements[0]);
      properties = {};
      $this.children('ol-property').each(function() {
        var coord, key, val;
        key = $(this).attr('name');
        val = $(this).text();
        val = (function() {
          var i, j, k, len, len1, len2, ref, ref1, ref2, results, results1, results2;
          switch (key) {
            case 'center':
              ref = val.split(',');
              results = [];
              for (i = 0, len = ref.length; i < len; i++) {
                coord = ref[i];
                results.push(parseFloat(coord));
              }
              return results;
            case 'constrainRotation':
              switch (val) {
                case 'true':
                  return true;
                case 'false':
                  return false;
                default:
                  return parseInt(val, 10);
              }
              break;
            case 'enableRotation':
              return val !== 'false';
            case 'extent':
              ref1 = val.split(',');
              results1 = [];
              for (j = 0, len1 = ref1.length; j < len1; j++) {
                coord = ref1[j];
                results1.push(parseFloat(coord));
              }
              return results1;
            case 'maxResolution':
              return parseFloat(val);
            case 'minResolution':
              return parseFloat(val);
            case 'maxZoom':
              return parseInt(val, 10);
            case 'minZoom':
              return parseInt(val, 10);
            case 'projection':
              return val;
            case 'resolution':
              return parseFloat(val);
            case 'resolutions':
              ref2 = val.split(',');
              results2 = [];
              for (k = 0, len2 = ref2.length; k < len2; k++) {
                coord = ref2[k];
                results2.push(parseFloat(coord));
              }
              return results2;
            case 'rotation':
              return parseFloat(val);
            case 'zoom':
              return parseInt(val, 10);
            case 'zoomFactor':
              return parseFloat(val);
            default:
              throw "Usupported view property: '" + key + "'";
          }
        })();
        return properties[key] = val;
      });
      _mapProjection = properties.projection = (ref = properties.projection) != null ? ref : _mapProjection;
      if (properties.center != null) {
        properties.center = ol.proj.transform(properties.center, _configProjection, properties.projection);
      }
      if (properties.extent != null) {
        properties.extent = ol.proj.transformExtent(properties.extent, _configProjection, properties.projection);
      }
      return new ol.View(properties);
    };

    OlParser.prototype._getOlConfig = function($element) {
      var deferred;
      deferred = $.Deferred();
      if ($element.attr('src')) {
        $.ajax({
          url: $element.attr('src'),
          dataType: "xml",
          cache: true,
          success: (function(_this) {
            return function(data, textStatus, jqxhr) {
              return deferred.resolve($(data).children('ol-configuration'));
            };
          })(this),
          error: (function(_this) {
            return function(jqXHR, textStatus, errorThrown) {
              return deferred.reject(textStatus);
            };
          })(this)
        });
      } else {
        deferred.resolve($($.parseXML($element.children('script[type="application/xml"]').text())).children('ol-configuration'));
      }
      return deferred;
    };

    OlParser.prototype.getLayers = function() {
      return _layers.slice();
    };

    OlParser.prototype.getVectorLayers = function() {
      var i, layer, len, results;
      results = [];
      for (i = 0, len = _layers.length; i < len; i++) {
        layer = _layers[i];
        if (layer.get('source') instanceof ol.source.Vector) {
          results.push(layer);
        }
      }
      return results;
    };

    OlParser.prototype.parseMap = function(element, options) {
      var $element;
      _configProjection = options.projection ? options.projection : 'EPSG:4326';
      $element = (function() {
        switch (false) {
          case !(element instanceof $):
            return element;
          case typeof element !== 'string':
            return $("" + element);
          case !this._isDomNode(element):
            return $(element);
          default:
            throw "Unknown element";
        }
      }).call(this);
      if ($element.length === 0) {
        throw "Unknown element";
      }
      _configProjection = $element.attr('projection') ? $element.attr('projection') : _configProjection;
      return this._getOlConfig($element).then((function(_this) {
        return function($olConfig) {
          var interactions, map;
          _styleParser.parseStyles($olConfig);
          map = new ol.Map({
            target: $element[0],
            view: _this._parseView($olConfig),
            layers: _this._parseOlLayers($olConfig)
          });
          _map = map;
          interactions = new OlInteractions(map);
          interactions.dragCursor();
          interactions.hoverCursor();
          interactions.popups();
          interactions.tooltips();
          setTimeout((function() {
            return $element.trigger({
              type: 'jquery-ol.map.initialized',
              map: map
            });
          }), 10);
        };
      })(this));
    };

    return OlParser;

  })();

  (function() {
    var exported;
    exported = {
      init: function(_options) {
        var $this, jqol, options;
        options = $.extend({}, $.fn.jqOpenLayers.defaults, _options);
        $this = $(this);
        jqol = new OlParser();
        $this.data('JqOpenLayers', jqol);
        jqol.parseMap($this, options);
        return $this;
      },
      getLayers: function() {
        var $this, jqol;
        $this = $(this);
        jqol = $this.data('JqOpenLayers');
        return jqol.getLayers();
      },
      getVectorLayers: function() {
        var $this, jqol;
        $this = $(this);
        jqol = $this.data('JqOpenLayers');
        return jqol.getVectorLayers();
      }
    };
    $.fn.jqOpenLayers = function(options) {
      var _arguments;
      _arguments = arguments;
      if (exported[options] && exported[options] !== 'init') {
        if ($(this).length !== 1) {
          $.error("Cannot invoke the method '" + options + "' on multiple elements");
        } else {
          return exported[options].apply(this, Array.prototype.slice.call(_arguments, 1));
        }
      }
      geoLib.loadOpenLayers().then((function(_this) {
        return function() {
          return _this.each(function() {
            if (typeof options === 'object' || !options || (exported[options] && exported[options] === 'init')) {
              return exported['init'].apply(this, options);
            } else {
              return $.error("The method '" + options + "' does not exist on jQuery.jqOpenLayers");
            }
          });
        };
      })(this));
      return $(this);
    };
    $.fn.jqOpenLayers.defaults = {
      projection: null,
      enablePopups: false,
      enableTooltips: false,
      onLayerAdded: null,
      onLayerLoaded: null
    };
  })();

}).call(this);
