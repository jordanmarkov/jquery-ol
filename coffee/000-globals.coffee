# global variables go here
root = exports ? this

$ = jQuery
$window = $(window)
$document = $(document)
$html = $('html')
$head = $('head')
$body = $('body')

String::startsWith ?= (s) -> @[...s.length] is s
String::endsWith ?= (s) -> s is '' or @[-s.length..] is s
String::trim ?= -> @.replace(/^\s+|\s+$/g, '')
# these are non-standard anyways
#String::trimStart ?= (s) -> if @.startsWith s then @[(s.length)..] else @
#String::trimEnd ?= (s) -> if @.endsWith s then @[...(-s.length)] else @
