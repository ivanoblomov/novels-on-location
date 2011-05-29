// Adapted from http://gmaps-samples-v3.googlecode.com/svn/trunk/latlng-to-coord-control/latlng-to-coord-control.html

/**
 * LatLngControl class displays the LatLng and pixel coordinates
 * underneath the mouse within a container anchored to it.
 * @param {google.maps.Map} map Map to add custom control to.
 */
function LatLngControl(map) {
  /**
   * Offset the control container from the mouse by this amount.
   */
  this.ANCHOR_OFFSET_ = new google.maps.Point(8, 8);

  /**
   * Pointer to the HTML container.
   */
  this.node_ = this.createHtmlNode_();

  // Add control to the map. Position is irrelevant.
  map.controls[google.maps.ControlPosition.TOP].push(this.node_);

  // Bind this OverlayView to the map so we can access MapCanvasProjection
  // to convert LatLng to Point coordinates.
  this.setMap(map);

  // Register an MVC property to indicate whether this custom control
  // is visible or hidden. Initially hide control until mouse is over map.
  this.set('visible', false);
}

// Extend OverlayView so we can access MapCanvasProjection.
LatLngControl.prototype = new google.maps.OverlayView();
LatLngControl.prototype.draw = function() {};

/**
 * @private
 * Helper function creates the HTML node which is the control container.
 * @return {HTMLDivElement}
 */
LatLngControl.prototype.createHtmlNode_ = function() {
  var divNode = document.createElement('div');
  divNode.id = 'latlng-control';
  divNode.index = 100;
  return divNode;
};

/**
 * MVC property's state change handler function to show/hide the
 * control container.
 */
LatLngControl.prototype.visible_changed = function() {
  this.node_.style.display = this.get('visible') ? '' : 'none';
};

/**
 * Specified LatLng value is used to calculate pixel coordinates and
 * update the control display. Container is also repositioned.
 * @param {google.maps.LatLng} latLng Position to display
 */
LatLngControl.prototype.updatePosition = function(latLng) {
  var projection = this.getProjection();
  var point = projection.fromLatLngToContainerPixel(latLng);

  // Update control position to be anchored next to mouse position.
  this.node_.style.left = point.x + this.ANCHOR_OFFSET_.x + 'px';
  this.node_.style.top = point.y + this.ANCHOR_OFFSET_.y + 'px';

  // Update control to display latlng and coordinates.
  this.node_.innerHTML = [
    latLng.toUrlValue(4)
  ].join('');
};

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

  // Create new control to display latlng and coordinates under mouse.
  var latLngControl = new LatLngControl(map);

  // Register event listeners
  google.maps.event.addListener(map, 'mouseover', function(e) {
    latLngControl.set('visible', true);
  });
  google.maps.event.addListener(map, 'mouseout', function(e) {
    latLngControl.set('visible', false);
  });
  google.maps.event.addListener(map, 'mousemove', function(e) {
    latLngControl.updatePosition(e.latLng);
  });
  google.maps.event.addListener(map, 'click', function(e) {
    promptForTitle(e.latLng);
  });
  Event.observe($('book-input'), 'blur', function(e) {
    Event.element(e).value = bookPrompt;
  });
  Event.observe($('book-input'), 'focus', function(e) {
    Event.element(e).value = '';
  });
  Event.observe($('book-input'), 'keydown', function(e) {
    if (e.keyCode == Event.KEY_RETURN) {
      findMappedBooks($('book-input').value);
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

function promptForTitle(latLng) {
  var bookTitle = prompt("Enter the book's title", null);

  if (bookTitle) {
    findBook(latLng, bookTitle);
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

function findBook(latLng, title) {
  new Ajax.Request('/locations?location[title]=' + title + '&location[latLng]=' + latLng.toUrlValue(), {
    method: 'post'
  });
}

function findMappedBooks(title) {
  new Ajax.Request('/locations?location[title]=' + title, {
    method: 'get'
  });
}

function codePlace(input) {
  geocoder.geocode( { 'address': input}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      r = results[0];
      zoomIn(r.geometry.location);

      if (shouldAddPin(r)) {
        promptForTitle(r.geometry.location);
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

function updateCoordinates(id, latLng) {
  new Ajax.Request('/locations/' + id + '?location[latLng]=' + latLng.toUrlValue(), {
    method: 'put'
  });
}
