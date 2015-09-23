define(['cs!utils'], function(Utils){
    "use strict";
    var utils = new Utils();
    utils.geocode('Sofia, bulgaria').then(function(result) {
        console.log(result);
    });
});
