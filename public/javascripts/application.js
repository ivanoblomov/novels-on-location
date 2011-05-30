// Adapted from http://code.google.com/apis/maps/documentation/javascript/examples/icon-complex.html

var bookPrompt = 'Find a mapped book';
var geocoder;
var map;
var markers = {};
var openWindow;
var placePrompt = 'Find a place and map a book to it';
var r;

function initializeMap() {
  var myOptions = {
    backgroundColor: 'white',
    center: locations[0] && locations[0]['latLng'] || new google.maps.LatLng(0, 0),
    mapTypeId: google.maps.MapTypeId.HYBRID,
    zoom: 2
  };

  geocoder = new google.maps.Geocoder();
  map = new google.maps.Map($('map-canvas'), myOptions);
  zoomer = new google.maps.MaxZoomService();

  for (var i = 0; i < locations.length; i++) {
    addPin(locations[i]['id'], locations[i]['latLng'], locations[i]['content']);
  }

  // Set prompts
  $('book-input').value = bookPrompt;
  $('place-input').value = placePrompt;

  // Register event listeners
  google.maps.event.addListener(map, 'click', function(e) {
    promptForTitle('', e.latLng);
  });
  Event.observe($('book-input'), 'blur', function(e) {
    Event.element(e).value = bookPrompt;
  });
  Event.observe($('book-input'), 'focus', function(e) {
    Event.element(e).value = '';
  });
  Event.observe($('book-input'), 'keydown', function(e) {
    if (e.keyCode == Event.KEY_RETURN) {
      hideBookMarkers($('book-input').value);
    }
  });
  Event.observe($('place-input'), 'blur', function(e) {
    Event.element(e).value = placePrompt;
  });
  Event.observe($('place-input'), 'focus', function(e) {
    Event.element(e).value = '';
  });
  Event.observe($('place-input'), 'keydown', function(e) {
    if (e.keyCode == Event.KEY_RETURN) {
      codePlace(Event.element(e).value);
    }
  });
}

//

function promptForTag(id, tags) {
  var value = prompt("Enter some descriptive words. These will be linked to a Google search.", tags);

  if (value) {
    tagLocation(id, value);
  }
}

function promptForTitle(place, latLng) {
  var bookTitle = prompt("Enter the book's title", null);

  if (bookTitle) {
    findBook(place, latLng, bookTitle);
  }
}

function addPin(id, latLng, content) {
  var marker = new google.maps.Marker({
    map: map,
    draggable: true,
    animation: google.maps.Animation.DROP,
    position: latLng
  });

  markers[id] = marker;

  google.maps.event.addListener(marker, 'click', function() {
    openBalloon(marker, content);
  });

  google.maps.event.addListener(marker, 'dragend', function() {
    if (confirm('Move this pin?')) {
      updateCoordinates(id, marker.getPosition());
    } else {
      marker.setPosition(latLng);
    }
  });
}

function shouldAddPin(googleResults) {
  var types = googleResults['types'];
  var typesToPin = ['establishment', 'point_of_interest', 'street_address']

  for (var i = 0; i < typesToPin.length; i++) {
    if (types.indexOf(typesToPin[i]) >= 0) {
      return true;
    }
  }

  return false;
}

function hideBookMarkers(keyword) {
  for (var i = 0; i < locations.length; i++) {
    if (keyword != '' && locations[i]['terms'].search(eval('/' + keyword + '/i')) == -1) {
      hideMarker(locations[i]['id']);
    } else {
      markers[locations[i]['id']].setMap(map);
    }
  }
}

function hideMarker(id) {
  markers[id].setMap(null);
}

function findBook(place, latLng, title) {
  new Ajax.Request('/locations?location[tags]=' + place + '&location[amazon_title]=' + title + '&location[latLng]=' + latLng.toUrlValue(), {
    method: 'post'
  });
}

function codePlace(input) {
  geocoder.geocode( { 'address': input}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      r = results[0];
      zoomIn(r.geometry.location);

      if (shouldAddPin(r)) {
        promptForTitle(input, r.geometry.location);
      }
    } else {
      alert("Couldn't geocode! The error was " + status);
    }
  });
}

function zoomIn(latLng) {
  zoomer.getMaxZoomAtLatLng(latLng, function(response) {
    map.setCenter(latLng);

    if (response.status != google.maps.MaxZoomStatus.OK) {
      alert("Couldn't zoom!");
      map.setZoom(8);
      return;
    } else {
      map.setZoom(response.zoom - 3);
    }
  });
}

function openBalloon(marker, content) {
  if (openWindow != undefined) {
    openWindow.close();
  }

  openWindow = new google.maps.InfoWindow( {content: content} );
  openWindow.open(map, marker);
}

function tagLocation(id, tags) {
  new Ajax.Request('/locations/' + id + '?location[tags]=' + tags, {
    method: 'put'
  });
}

function updateCoordinates(id, latLng) {
  new Ajax.Request('/locations/' + id + '?location[latLng]=' + latLng.toUrlValue(), {
    method: 'put'
  });
}
