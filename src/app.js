requirejs.config({
    "paths": {
        "jquery": "/node_modules/jquery/dist/jquery.min",
        "ol3": "/node_modules/openlayers/dist/ol",
        "Q": "/node_modules/q/q"
    }
});

// Load the main app module to start the app
requirejs(["main"]);

