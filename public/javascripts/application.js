var bookPrompt = 'Find a mapped book';
var clickingZooms = true;
var clickListener;
var fb_session;
var geocoder;
var map;
var pins = {};
var openWindow;
var placePrompt = 'Find a place & map a book to it';
var r;

function initializeMap() {
  var myOptions = {
    backgroundColor: 'white',
    center: new google.maps.LatLng(0, 0),
    mapTypeId: google.maps.MapTypeId.HYBRID,
    minZoom: 2,
    zoom: 2
  };

  geocoder = new google.maps.Geocoder();
  map = new google.maps.Map($('#map-canvas')[0], myOptions);
  zoomer = new google.maps.MaxZoomService();

  for (var i = 0; i < locations.length - 1; i++) {
    addPin(locations[i]['id'], locations[i]['latLng'], locations[i]['content'], locations[i]['draggable']);
  }

  // Set prompts
  $('#book-input')[0].value = bookPrompt;
  $('#place-input')[0].value = placePrompt;

  // Register event listeners
  $('#book-input').blur( function() {
    $(this).attr('value', bookPrompt);
  });
  $('#book-input').focus( function() {
    $(this).attr('value', '');
  });
  $('#book-input').keyup( function() {
    hidePins($('#book-input')[0].value);
  });
  $('#place-input').blur( function() {
    $(this).attr('value', placePrompt);
  });
  $('#place-input').focus( function() {
    $(this).attr('value', '');
  });
  $('#place-input').keypress( function(e) {
    if ((e.keyCode || e.which) == 13) codePlace($(this).val());
  });

  applesearch.init();
}

function labelFacebookButton(value) {
  $('#fb-root')[0].value = value;
}

function listenFor(event, args) {
  if (clickListener != undefined) google.maps.event.removeListener(clickListener);
  clickListener = google.maps.event.addListener(map, event, function(e) {eval(args)});
}

function listenForLogin() {
  labelFacebookButton('Log In \u00a0 ');
  $('#fb-root').click( function() {
    logIn();
  });
}

function listenForLogout() {
  labelFacebookButton('Log Out\u00a0');
  $('#fb-root').click( function() {
    logOut();
  });
}

function logIn() {
  FB.login(function(response) {
    if (response.session) {
      fb_session = response.session
      $.cookie('fb_id', fb_session.uid)
      window.location.reload();
      listenForLogout();
    }
  });
}

function logOut() {
  FB.logout(function(response) {
    $.cookie('fb_id', null)
    window.location.reload();
    listenForLogin();
  });
}

function promptForTag(id, tags) {
  var value = prompt("Enter some descriptive words. These will be linked to a Google search.", tags);
  if (value) tagPin(id, value);
}

function promptForBook(latLng, place, address) {
  var keywords = prompt("Enter keywords describing the book: title, author, etc.", null);
  if (keywords) findBook(latLng, place || '', address, keywords);
}

function toggleMapMode() {
  clickingZooms = ! clickingZooms;

  if (clickingZooms) {
    if (clickListener != undefined) google.maps.event.removeListener(clickListener);
    $('#mode-button')[0].title = 'Double-Click Map to Zoom';
    $('#mode-button')[0].value = 'Zoom';
  } else {
    listenFor('dblclick', "promptForBook(e.latLng)");
    $('#mode-button')[0].title = 'Double-Click Map to Add Pins';
    $('#mode-button')[0].value = 'Add Pins';
  }
}

function addPin(id, latLng, content, draggable) {
  var pin = new google.maps.Marker({
    map: map,
    draggable: draggable,
    animation: google.maps.Animation.DROP,
    position: latLng
  });

  pins[id] = pin;

  google.maps.event.addListener(pin, 'click', function() {
    openBalloon(pin, content);
  });

  google.maps.event.addListener(pin, 'dragend', function() {
    if (confirm('Move this pin?'))
      movePin(id, pin.getPosition());
    else
      pin.setPosition(latLng);
  });
}

function shouldAddPin(googleResults) {
  var types = googleResults['types'];
  var typesToPin = ['establishment', 'point_of_interest', 'street_address']

  for (var i = 0; i < typesToPin.length; i++) {
    if (types.indexOf(typesToPin[i]) >= 0) return true;
  }

  return false;
}

function hidePins(keyword) {
  for (var i = 0; i < locations.length; i++) {
    if (keyword != '' && locations[i]['terms'].search(eval('/' + keyword + '/i')) == -1)
      hidePin(locations[i]['id']);
    else
      pins[locations[i]['id']].setMap(map);
  }
}

function hidePin(id) {
  pins[id].setMap(null);
}

function codePlace(input) {
  geocoder.geocode( { 'address': input}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      r = results[0];
      zoomIn(r.geometry.location);

      if (shouldAddPin(r)) promptForBook(r.geometry.location, input, r.formatted_address);
    } else
      alert("Couldn't geocode! The error was " + status);
  });
}

function zoomIn(latLng) {
  zoomer.getMaxZoomAtLatLng(latLng, function(response) {
    map.setCenter(latLng);

    if (response.status != google.maps.MaxZoomStatus.OK) {
      alert("Couldn't zoom!");
      map.setZoom(8);
      return;
    } else
      map.setZoom(map.getZoom() == response.zoom - 5 ? response.zoom - 3: response.zoom - 5);
  });
}

function openBalloon(pin, content) {
  if (openWindow != undefined) openWindow.close();
  openWindow = new google.maps.InfoWindow( {content: content} );
  openWindow.open(map, pin);
  listenFor('click', "openWindow.close(); clickingZooms = ! clickingZooms; toggleMapMode()");
}

function claimPin(id) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'caller': 'claim',
      'location[user_id]': fb_session && fb_session.uid || null
    }
  });
}

function createPin(latLng, place, address, keywords) {
  $.post('/locations', {
    'location[address]': (address || ''),
    'location[book_keywords]': keywords,
    'location[latLng]': latLng.toUrlValue(),
    'location[tags]': place,
    'location[user_id]': fb_session && fb_session.uid || null
  });
}

function findBook(latLng, place, address, keywords) {
  $.get('/locations/1', {
    'location[address]': (address || ''),
    'location[tags]': place,
    'location[book_keywords]': keywords,
    'location[latLng]': latLng.toUrlValue()
  });
}

function movePin(id, latLng) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[latLng]': latLng.toUrlValue()
    }
  });
}

function tagPin(id, tags) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[tags]': tags
    }
  });
}

// Adapted from http://www.brandspankingnew.net/archive/2005/08/adding_an_os_x.html
var applesearch;
if (!applesearch)	applesearch = {};

applesearch.init = function ()
{
	// add applesearch css for non-safari, dom-capable browsers
	if ( navigator.userAgent.toLowerCase().indexOf('safari') < 0  && document.getElementById )
	{
		this.clearBtn = false;
	}
}

// called when on user input - toggles clear fld btn
applesearch.onChange = function (fldID, btnID)
{
	// check whether to show delete button
	var fld = document.getElementById( fldID );
	var btn = document.getElementById( btnID );
	if (fld.value.length > 0 && !this.clearBtn)
	{
		btn.style.background = "white url('/images/srch_r_f2.gif') no-repeat top left";
		btn.fldID = fldID; // btn remembers it's field
		btn.onclick = this.clearBtnClick;
		this.clearBtn = true;
	} else if (fld.value.length == 0 && this.clearBtn)
	{
		btn.style.background = "white url('/images/srch_r.gif') no-repeat top left";
		btn.onclick = null;
		this.clearBtn = false;
	}
}

// clears field
applesearch.clearFld = function (fldID,btnID)
{
	var fld = document.getElementById( fldID );
	fld.value = "";
	this.onChange(fldID,btnID);

	if (fldID == 'book-input') {
    hidePins($('#book-input')[0].value);
	}
}

// called by btn.onclick event handler - calls clearFld for this button
applesearch.clearBtnClick = function ()
{
	applesearch.clearFld(this.fldID, this.id);
}

/**
 * Cookie plugin
 *
 * Copyright (c) 2006 Klaus Hartl (stilbuero.de)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 */

/**
 * Create a cookie with the given name and value and other optional parameters.
 *
 * @example $.cookie('the_cookie', 'the_value');
 * @desc Set the value of a cookie.
 * @example $.cookie('the_cookie', 'the_value', { expires: 7, path: '/', domain: 'jquery.com', secure: true });
 * @desc Create a cookie with all available options.
 * @example $.cookie('the_cookie', 'the_value');
 * @desc Create a session cookie.
 * @example $.cookie('the_cookie', null);
 * @desc Delete a cookie by passing null as value. Keep in mind that you have to use the same path and domain
 *       used when the cookie was set.
 *
 * @param String name The name of the cookie.
 * @param String value The value of the cookie.
 * @param Object options An object literal containing key/value pairs to provide optional cookie attributes.
 * @option Number|Date expires Either an integer specifying the expiration date from now on in days or a Date object.
 *                             If a negative value is specified (e.g. a date in the past), the cookie will be deleted.
 *                             If set to null or omitted, the cookie will be a session cookie and will not be retained
 *                             when the the browser exits.
 * @option String path The value of the path atribute of the cookie (default: path of page that created the cookie).
 * @option String domain The value of the domain attribute of the cookie (default: domain of page that created the cookie).
 * @option Boolean secure If true, the secure attribute of the cookie will be set and the cookie transmission will
 *                        require a secure protocol (like HTTPS).
 * @type undefined
 *
 * @name $.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */

/**
 * Get the value of a cookie with the given name.
 *
 * @example $.cookie('the_cookie');
 * @desc Get the value of a cookie.
 *
 * @param String name The name of the cookie.
 * @return The value of the cookie.
 * @type String
 *
 * @name $.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */
jQuery.cookie = function(name, value, options) {
    if (typeof value != 'undefined') { // name and value given, set cookie
        options = options || {};
        if (value === null) {
            value = '';
            options.expires = -1;
        }
        var expires = '';
        if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
            var date;
            if (typeof options.expires == 'number') {
                date = new Date();
                date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
            } else {
                date = options.expires;
            }
            expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
        }
        // CAUTION: Needed to parenthesize options.path and options.domain
        // in the following expressions, otherwise they evaluate to undefined
        // in the packed version for some reason...
        var path = options.path ? '; path=' + (options.path) : '';
        var domain = options.domain ? '; domain=' + (options.domain) : '';
        var secure = options.secure ? '; secure' : '';
        document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
    } else { // only name given, get cookie
        var cookieValue = null;
        if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
                var cookie = jQuery.trim(cookies[i]);
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, name.length + 1) == (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
};