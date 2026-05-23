var _tsq = _tsq || [];
_tsq.push(["setAccountName", "novelsonlocation"]);
_tsq.push(["enableGoogleAnalyticsIntegration", true]);
_tsq.push(["fireHit", "javascript_tracker", []]);
(function() {
    function z(){
        var s = document.createElement("script");
        s.async = "async";
        s.src = window.location.protocol + "//cdn.tapstream.com/static/js/tapstream.js";
        var x = document.getElementsByTagName("script")[0];
        x.parentNode.insertBefore(s, x);
    }
    if (window.attachEvent)
        window.attachEvent("onload", z);
    else
        window.addEventListener("load", z, false);
})();
