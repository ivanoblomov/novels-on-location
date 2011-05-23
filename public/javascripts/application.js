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

var map;
var openWindow;

function initializeMap() {
  var myOptions = {
    center: locations[0] && locations[0]['latLng'] || new google.maps.LatLng(0, 0),
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    zoom: 3
  };

  map = new google.maps.Map(document.getElementById('map_canvas'), myOptions);

  for (var i = 0; i < locations.length; i++) {
    addBookMarker(locations[i]['latLng'], locations[i]['content']);
  }

  // Create new control to display latlng and coordinates under mouse.
  var latLngControl = new LatLngControl(map);

  // Register event listeners
  google.maps.event.addListener(map, 'mouseover', function(mEvent) {
    latLngControl.set('visible', true);
  });
  google.maps.event.addListener(map, 'mouseout', function(mEvent) {
    latLngControl.set('visible', false);
  });
  google.maps.event.addListener(map, 'mousemove', function(mEvent) {
    latLngControl.updatePosition(mEvent.latLng);
  });
  google.maps.event.addListener(map, 'click', function(mEvent) {
    promptForTitle(mEvent);
  });
}

//

function promptForTitle(mEvent) {
  var bookTitle = prompt('Title', '');

  if (bookTitle) {
    findBook(mEvent, bookTitle);
  }
}

function addBookMarker(latLng, content) {
  var marker = new google.maps.Marker({
    map: map,
    draggable: true,
    animation: google.maps.Animation.DROP,
    position: latLng
  });

  google.maps.event.addListener(marker, 'click', function() {
    if (openWindow != undefined) {
      openWindow.close();
    }

    openWindow = new google.maps.InfoWindow( {content: content} );
    openWindow.open(map, marker);
    $('open-balloon').parentNode.style.overflow = 'visible';
  });
}

function findBook(mEvent, title) {
  new Ajax.Request('/locations/' + title + '?lat_lng=' + mEvent.latLng.toUrlValue(), {
    method: 'get',
    onSuccess: function(response) {
      addBookMarker(mEvent, response.responseText);
    }
});}
