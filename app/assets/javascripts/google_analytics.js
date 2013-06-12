var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-25642977-1']);
_gaq.push(['_trackPageview']);
(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
var _tsq = _tsq || [];
_tsq.push(["setAccountName", "novelsonlocation"]);
_tsq.push(["enableGoogleAnalyticsIntegration", true]);
_tsq.push(["fireHit", "javascript_tracker", []]);
(function() {
    function z(){
        var s = document.createElement("script");
        s.type = "text/javascript";
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