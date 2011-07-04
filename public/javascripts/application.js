// Adapted from http://code.google.com/apis/maps/documentation/javascript/examples/icon-complex.html
var bookPrompt = 'Find a mapped book';
var clickingZooms = true;
var clickListener;
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

  for (var i = 0; i < locations.length; i++) {
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

  FB.getLoginStatus(function(response) {
    if (response.session)
      $('.fb_button_text')[0].replaceWith('<span class="fb_button_text" onclick="logOut()">Log Out</span>');
  });
  applesearch.init();
}

function listenFor(element, event, args) {
  if (clickListener != undefined) google.maps.event.removeListener(clickListener);
  clickListener = google.maps.event.addListener(element, event, function(e) {eval(args)});
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
    listenFor(map, 'dblclick', "promptForBook(e.latLng)");
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
      updatePin(id, pin.getPosition());
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

      if (shouldAddPin(r)) {
        promptForBook(r.geometry.location, input, r.formatted_address);
      }
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

function logOut() {
  FB.logout(function(response) {});
}

function openBalloon(pin, content) {
  if (openWindow != undefined) openWindow.close();
  openWindow = new google.maps.InfoWindow( {content: content} );
  openWindow.open(map, pin);
  listenFor(map, 'click', "openWindow.close(); clickingZooms = ! clickingZooms; toggleMapMode()");
}

function createPin(latLng, place, address, keywords) {
  $.post('/locations', {
    'location[address]': (address || ''),
    'location[tags]': place,
    'location[book_keywords]': keywords,
    'location[latLng]': latLng.toUrlValue()
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

function tagPin(id, tags) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[tags]': tags
    }
  });
}

function updatePin(id, latLng) {
  $.ajax({
    type: 'PUT',
    url: '/locations/' + id,
    data: {
      'location[latLng]': latLng.toUrlValue()
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
