var bookPrompt = 'Find a mapped book';
var clickingZooms = true;
var clickListener;
var fb_session;
var friendIds = [];
var friends;
var geocoder;
var locations;
var map;
var pins = {};
var openWindow;
var placePrompt = 'Find a place & map a book to it';
var r;
var showingAllPins = true;

function initializeMap(selectedLocationId) {
  var myOptions = {
    backgroundColor: 'white',
    center: new google.maps.LatLng(0, 0),
    draggableCursor: 'default',
    mapTypeId: google.maps.MapTypeId.HYBRID,
    minZoom: 2,
    zoom: 2
  };

  geocoder = new google.maps.Geocoder();
  map = new google.maps.Map($('#map-canvas')[0], myOptions);
  zoomer = new google.maps.MaxZoomService();
  getLocations(selectedLocationId);

  // Set prompts
  $('#book-input')[0].value = bookPrompt;
  $('#place-input')[0].value = placePrompt;

  // Register event listeners
  $('#book-input').blur( function() {
    if ($(this).attr('value') == '') {
      $(this).attr('value', bookPrompt);
      hidePins('');
    }
    $(this).css('color', '#777');
    listenForShortcuts();
  });
  $('#book-input').focus( function() {
    if ($(this).attr('value') == bookPrompt)
      $(this).attr('value', '');
    $(this).css('color', 'black');
    dontListenForShortcuts();
  });
  $('#book-input').keyup( function() {
    hidePins($('#book-input')[0].value);
  });
  $('#mode-button').click(toggleMapMode);
  $('#pin-display-button').click(togglePinDisplay);
  $('#place-input').blur( function() {
    $(this).attr('value', placePrompt);
    $(this).css('color', '#777');
    listenForShortcuts();
  });
  $('#place-input').focus( function() {
    $(this).attr('value', '');
    $(this).css('color', 'black');
    dontListenForShortcuts();
  });
  $('#place-input').keypress( function(e) {
    if ((e.keyCode || e.which) == 13) codePlace($(this).val());
  });

  listenForShortcuts();
  applesearch.init();
}

function captureFacebookSession(session) {
  fb_session = session
  $.cookie('fb_id', fb_session.uid)
}

function getFacebookName(location) {
  if (location.user_name == undefined) {
    FB.api('/' + location.user_id, function(response) {
      location.user_name = response.name;
    });
  }
}

function getFriendIds() {
  for (var i = 0; i < friends.length; i++) {
    friendIds[i] = friends[i].id;
  }
}

function getFriendName(id) {
  if (id == fb_session.uid)
    return 'You';
  for (var i = 0; i < friends.length; i++) {
    if (friends[i].id == id)
      return friends[i].name;
  }
}

function getFriends() {
  FB.api('/me/friends', function(response) {
    friends = response.data;
    setLocationUserNames();
    getFriendIds();
  });
}

function labelFacebookButton(value, title) {
  $('#login-button')[0].value = value;
  $('#login-button')[0].title = title;
}

function listenFor(event, args) {
  if (clickListener != undefined) google.maps.event.removeListener(clickListener);
  clickListener = google.maps.event.addListener(map, event, function(e) {eval(args)});
}

function listenForLogin() {
  $('#login-button').click( function() {
    toggleLogin();
  });
}

function dontListenForShortcuts() {
  shortcut.remove('l');
  shortcut.remove('m');
  shortcut.remove('s');
}

function listenForShortcuts() {
  shortcut.add('l', toggleLogin);
  shortcut.add('m', toggleMapMode);
  shortcut.add('s', togglePinDisplay);
}

function loggedIn() {
  return !! $.cookie('fb_id');
}

function logIn() {
  FB.login(function(response) {
    if (response.session) {
      labelFacebookButton('Log Out\u00a0', 'Log out of Facebook');
      captureFacebookSession(response.session);
      window.location.reload();
      listenForLogout();
    }
  });
}

function logOut() {
  FB.logout(function(response) {
    labelFacebookButton('Log In \u00a0 ', 'Log into Facebook');
    $.cookie('fb_id', null)
    window.location.reload();
    listenForLogin();
  });
}

function toggleLogin() {
  loggedIn() ? logOut() : logIn();
}

function promptForTag(id, tags) {
  var value = prompt('Enter some descriptive words. These will be linked to a Google search.', tags);
  if (value) tagPin(id, value);
}

function promptForNotes(id, notes) {
  var value = prompt('Add any comments you would like readers to know.', notes);
  if (value) annotatePin(id, value);
}

function promptForBook(gLatLng, place, address) {
  var keywords = prompt('Enter keywords describing the book: title, author, etc.', null);
  if (keywords) findBook(gLatLng, place || '', address, keywords);
}

function toggleMapMode() {
  clickingZooms = ! clickingZooms;

  if (clickingZooms) {
    if (clickListener != undefined) google.maps.event.removeListener(clickListener);
    $('#mode-button')[0].title = 'Double-click map to zoom. Click to toggle';
    $('#mode-button')[0].value = 'Mode: Zoom';
    map.setOptions({
      draggableCursor: 'default',
      disableDoubleClickZoom: false
    });
  } else {
    listenFor('dblclick', 'promptForBook(e.latLng)');
    $('#mode-button')[0].title = 'Double-click map to add pins. Click to toggle';
    $('#mode-button')[0].value = 'Mode: Add Pins';
    map.setOptions({
      draggableCursor: 'crosshair',
      disableDoubleClickZoom: true
    });
  }
}

function setPinDisplayPrompt() {
  $('#pin-display-button')[0].title = loggedIn() ? "Click to show only friends' pins" : 'Click to show only my pins';
  $('#pin-display-button')[0].value = loggedIn() ? "Show Friends'" : 'Show My Pins';
}

function togglePinDisplay() {
  showingAllPins = ! showingAllPins;

  if (showingAllPins) {
    showAllPins();
    setPinDisplayPrompt();
  } else {
    hideStrangersPins();
    $('#pin-display-button')[0].title = 'Click to show all pins';
    $('#pin-display-button')[0].value = 'Show All Pins';
  }
}

function addPin(location) {
  var pin = new google.maps.Marker({
    map: map,
    draggable: location.writable,
    animation: google.maps.Animation.DROP,
    position: toLatLng(location.lat_lng)
  });

  pins[location._id] = pin;

  google.maps.event.addListener(pin, 'click', function() {
    openBalloon(location);
  });

  google.maps.event.addListener(pin, 'dragend', function() {
    if (confirm('Move this pin?'))
      movePin(location._id, pin.getPosition());
    else
      pin.setPosition(toLatLng(location.lat_lng));
  });
}

function addPins(selectedLocationId) {
  for (var i = 0; i < locations.length; i++) {
    addPin(locations[i]);

    if (selectedLocationId && locations[i]._id == selectedLocationId) {
      openBalloon(locations[i]);
      zoomIn(toLatLng(locations[i].lat_lng));
    }
  }
}

function claimMyPins() {
  for (var i = 0; i < locations.length; i++) {
    // does the pin writable but missing an fb id?
    if (locations[i].writable && locations[i].user_id == undefined) {
      claimPin(locations[i]._id);
    }
  }
}

function shouldAddPin(googleResults) {
  var types = googleResults.types;
  var typesToPin = ['establishment', 'point_of_interest', 'street_address']

  for (var i = 0; i < typesToPin.length; i++) {
    if ($.inArray(typesToPin[i], types)) return true;
  }

  return false;
}

function hidePins(keyword) {
  for (var i = 0; i < locations.length; i++) {
    if (keyword != '' && locations[i].terms.search(eval('/' + keyword + '/i')) == -1)
      hidePin(locations[i]._id);
    else
      pins[locations[i]._id].setMap(map);
  }
}

function hidePin(id) {
  pins[id].setMap(null);
}

function hideStrangersPins() {
  for (var i = 0; i < locations.length; i++) {
    var pinId = locations[i]._id;
    var pinUserId = locations[i].user_id;

    if (! locations[i].writable && (! loggedIn() || (loggedIn() && $.inArray(pinUserId, friendIds) == -1)))
      hidePin(pinId);
    else
      pins[pinId].setMap(map);
  }
}

function setLocationUserNames() {
  for (var i = 0; i < locations.length; i++) {
    if (locations[i].user_name == undefined && locations[i].user_id)
      locations[i].user_name = getFriendName(locations[i].user_id) || getFacebookName(locations[i]);
  }
}

function showAllPins() {
  for (var i = 0; i < locations.length; i++) {
    pins[locations[i]._id].setMap(map);
  }
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

function zoomIn(gLatLng) {
  zoomer.getMaxZoomAtLatLng(gLatLng, function(response) {
    map.setCenter(gLatLng);

    if (response.status != google.maps.MaxZoomStatus.OK) {
      alert("Couldn't zoom!");
      map.setZoom(8);
      return;
    } else
      map.setZoom(map.getZoom() == response.zoom - 5 ? response.zoom - 3: response.zoom - 5);
  });
}

function openBalloon(location) {
  if (openWindow != undefined) openWindow.close();
  html = '<div class="map-balloon">';
  if (location.user_id == null && location.user_token == null) html += '<input onClick="claimPin(\'' + location._id + '\')" type="button" value="Claim" title="Claim This Pin" />';
  if (location.writable) html += '<input onClick="deletePin(\'' + location._id + '\')" type="button" value="Delete" title="Delete This Pin" /><input onClick="promptForTag(\'' + location._id + '\', \'' + location.tags + '\')" type="button" value="Tag" title="Tag Pin" /><input onClick="promptForNotes(\'' + location._id + '\', \'' + (location.notes || '') + '\')" type="button" value="Annotate" title="Annotate Pin" />';
  html += '<input onClick="zoomIn(toLatLng([' + location.lat_lng + ']))" type="button" value="Zoom" title="Zoom to Pin" /><h1><a href="' + location.url + '" target="_blank"><img src="' + location.image_url + '" alt="Cover of ' + location.title + '" class="thumbnail" height=' + location.image_height + ' width=' + location.image_width + ' />' + location.title + '</a></h1> <h2>by <a href="http://en.wikipedia.org/wiki/' + encodeURI(location.author) + '" target="_blank">' + location.author + '</a></h2><h2>' + location.address + '</h2><p>' + location.review + '</p>';
  if (location.notes) html += '<h3>Reader Notes</h3><p>' + location.notes + '</p><p>'
  if (fb_session && location.user_id) {
    html += 'Added by <a href="http://www.facebook.com/profile.php?id=' + location.user_id + '" id="' + location.user_id + '" target="_blank">' + (location.user_name || 'You') + '</a> on ' + location.added_at + '<br />';
  } else {
    html += 'Added on ' + location.added_at + '<br />';
  }
  if (location.tags) html += 'Tags: <a href="http://www.google.com/search?q=' + encodeURI(location.tags) + '" target="_blank">' + location.tags + '</a>'
  html += '</p></div>';
  openWindow = new google.maps.InfoWindow( {content: html} );
  openWindow.open(map, pins[location._id]);
  listenFor('click', 'openWindow.close(); clickingZooms = ! clickingZooms; toggleMapMode()');
}

function annotatePin(id, notes) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[notes]': notes
    }
  });
}

function claimPin(id) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'caller': 'claim',
      'location[user_id]': fb_session && fb_session.uid || null,
      'location[user_token]': $.cookie('user_token')
    }
  });
}

function createPin(latLng, place, address, keywords) {
  $.post('/locations', {
    'location[address]': (address || ''),
    'location[book_keywords]': keywords,
    'location[latLng]': toLatLng(latLng).toUrlValue(),
    'location[tags]': place,
    'location[user_id]': fb_session && fb_session.uid || null,
    'location[user_token]': $.cookie('user_token')
  });
}

function deletePin(id) {
  if (confirm('Are you sure? This action cannot be undone.')) {
    $.ajax({
      type: 'DELETE',
      url: '/locations/' + id
    })
  }
}

function findBook(gLatLng, place, address, keywords) {
  $.get('/locations/new', {
    'location[address]': (address || ''),
    'location[tags]': place,
    'location[book_keywords]': keywords,
    'location[latLng]': gLatLng.toUrlValue()
  });
}

function getLocations(selectedLocationId) {
  $.get('/locations.json', {'t': new Date().getTime(), 'user_token': $.cookie('user_token')}, function(data) {
    locations = data;
    addPins(selectedLocationId);
  });
}

function movePin(id, gLatLng) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[latLng]': gLatLng.toUrlValue()
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

function toLatLng( latLng ) {
	return new google.maps.LatLng(latLng[0], latLng[1]);
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
	fld.value = '';
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