//= require jquery_ujs
//= require shortcut
//= require_tree .
const anchorKindToLocationProperty = {
	author: "author",
	novel: "title",
	place: "place",
	reader: "user_id",
	search: "terms",
};
var nOL = {};
nOL.anchor = unescape(window.location.hash.substring(2));
nOL.anchorKind = nOL.anchor.split("-")[0];
nOL.bookPrompt = "Find a mapped book";
nOL.clickingZooms = true;
nOL.clickListener;
nOL.defaultTitle;
nOL.fb_session;
nOL.friendIds = [];
nOL.friends;
nOL.host;
nOL.locations;
nOL.map;
nOL.openWindow;
nOL.pins = {};
nOL.pinType = 0;
nOL.placePrompt = "Find a place & map a book to it";
nOL.r;
nOL.sharingMessage =
	"I%20found%20a%20book%20you%20might%20like%20with%20Novels%3A%20On%20Location,%20now%20available%20at%20the%20App%20Store%20http://AppStore.com/NovelsOnLocation";
nOL.twitterAccount = "NovelsOnLoc%3ANovels%3A%20On%20Location";

nOL.anchorQuery = nOL.anchor.split("-")[1] || nOL.anchorKind;

nOL.init = function (settings) {
	nOL.defaultTitle = settings.defaultTitle;
	nOL.host = settings.host;
	FB.init({
		appId: settings.fbAppId,
		cookie: true,
		status: true,
		version: "v2.11",
		xfbml: true,
	});
	FB.getLoginStatus(function (response) {
		nOL.statusChangeCallback(response);
	});

	nOL.bounds = new google.maps.LatLngBounds();
	nOL.geocoder = new google.maps.Geocoder();
	nOL.map = new google.maps.Map($("#map-canvas")[0], {
		backgroundColor: "white",
		center: new google.maps.LatLng(0, 0),
		draggableCursor: "default",
		mapTypeId: google.maps.MapTypeId.HYBRID,
		minZoom: 2,
	});
	nOL.zoomer = new google.maps.MaxZoomService();
	nOL.getLocations(settings.selectedLocationSlug);

	// Set prompts
	$("#book-input")[0].value = nOL.bookPrompt;
	$("#place-input")[0].value = nOL.placePrompt;

	nOL.updateShareButtons();

	// Register event listeners
	$("#book-input").blur(function () {
		if ($(this).val() === "") {
			$(this).val(nOL.bookPrompt);
			nOL.showAllPinsAndUpdatePath();
		}
		$(this).css("color", "#777");
		nOL.listenForShortcuts();
	});
	$("#book-input").focus(function () {
		if ($(this).val() === nOL.bookPrompt) $(this).val("");
		$(this).css("color", "black");
		nOL.dontListenForShortcuts();
	});
	$("#book-input").keyup(function () {
		var keyword = $("#book-input")[0].value;
		nOL.anchorKind = unescape(window.location.hash.substring(2)).split("-")[0];
		nOL.showPins(keyword, "#!search-" + escape(keyword));
	});
	$("#mode-button").click(nOL.toggleMapMode);
	$("#pin-display-button").click(nOL.togglePinDisplay);
	$("#place-input").blur(function () {
		$(this).val(nOL.placePrompt);
		$(this).css("color", "#777");
		nOL.listenForShortcuts();
	});
	$("#place-input").focus(function () {
		$(this).val("");
		$(this).css("color", "black");
		nOL.dontListenForShortcuts();
	});
	$("#place-input").keypress(function (e) {
		if ((e.keyCode || e.which) === 13) nOL.codePlace($(this).val());
	});

	nOL.listenForLogin();
	nOL.listenForShortcuts();
	applesearch.init();

	if (settings.error) alert(settings.error);
};

nOL.statusChangeCallback = function (response) {
	if (response.status === "connected") {
		nOL.initSession(response.authResponse);
	} else {
		$.cookie("fb_id", null);
	}
};

nOL.initSession = function (session) {
	nOL.fb_session = session;
	$.cookie("fb_id", nOL.fb_session.userID);
	nOL.setPinDisplayPrompt();
	nOL.getFriends();
};

nOL.checkOrientation = function () {
	var portrait = false;

	if (window.orientation != null) portrait = Math.abs(orientation) != 90;

	return portrait;
};

nOL.getFacebookName = function (location) {
	if (location.user_name === undefined && location.user_id) {
		FB.api("/" + location.user_id, function (response) {
			$("#" + location.user_id).text(response.name);
			location.user_name = response.name;
		});
	}
};

nOL.getFriendIds = function () {
	for (var i = 0; i < nOL.friends.length; i++) {
		nOL.friendIds[i] = nOL.friends[i].id;
	}
};

nOL.getFriends = function () {
	FB.api("/me/friends", function (response) {
		nOL.friends = response.data;
		nOL.getFriendIds();
	});
};

nOL.updateFacebookLikeButton = function () {
	var likeButton = $("#fb-like")[0];
	likeButton.dataset["href"] = document.URL;
};

nOL.updateShareButtons = function () {
	nOL.updateFacebookLikeButton();
	nOL.updateTweetButton();
};

nOL.updateTweetButton = function () {
	var iframe = $("#tweet")[0];
	iframe.src = iframe.src.replace(
		/\?.+/,
		"?related=" +
			nOL.twitterAccount +
			"&text=" +
			nOL.sharingMessage +
			"&url=" +
			document.URL,
	);
};

nOL.listenFor = function (event, args) {
	if (nOL.clickListener != undefined)
		google.maps.event.removeListener(nOL.clickListener);
	nOL.clickListener = google.maps.event.addListener(
		nOL.map,
		event,
		function (e) {
			eval(args);
		},
	);
};

nOL.listenForLogin = function () {
	$("#login-button").click(function () {
		nOL.toggleLogin();
	});
};

nOL.dontListenForShortcuts = function () {
	shortcut.remove("l");
	shortcut.remove("m");
	shortcut.remove("p");
};

nOL.listenForShortcuts = function () {
	shortcut.add("l", nOL.toggleLogin);
	shortcut.add("m", nOL.toggleMapMode);
	shortcut.add("p", nOL.togglePinDisplay);
};

nOL.loggedIn = function () {
	return !!$.cookie("fb_id");
};

nOL.logIn = function () {
	FB.login(function (response) {
		console.log(response);
		if (response.authResponse) {
			nOL.initSession(response.authResponse);
			document.location.reload();
		} else {
			console.log("193");
		}
	});
};

nOL.logOut = function () {
	console.log("logOut");
	FB.logout(function (response) {
		$.cookie("fb_id", null);
		nOL.listenForLogin();
	});
	console.log($.cookie("fb_id"));
	console.log("end");
};

nOL.toggleLogin = function () {
	nOL.loggedIn() ? nOL.logOut() : nOL.logIn();
};

nOL.processAnchorQuery = function () {
	switch (nOL.anchorKind) {
		case "author":
			nOL.pinType = 0;
			nOL.showPins(nOL.anchorQuery, window.location.hash);
			break;
		case "bookmarks":
			nOL.pinType = 2;
			nOL.showBookmarks();
			break;
		case "friends":
			nOL.pinType = 3;
			nOL.showFriendsPins();
			break;
		case "my":
			nOL.pinType = 1;
			nOL.showMyPins();
			break;
		case "novel":
			nOL.pinType = 0;
			nOL.showPins(nOL.anchorQuery, window.location.hash);
			break;
		case "place":
			nOL.pinType = 0;
			nOL.showPins(nOL.anchorQuery, window.location.hash);
			break;
		case "reader":
			nOL.pinType = 0;
			nOL.showPins(nOL.anchorQuery, window.location.hash);
			break;
		case "search":
			nOL.pinType = 0;
			nOL.showPins(nOL.anchorQuery, window.location.hash);
			break;
		default:
			nOL.pinType = 0;
			nOL.showAllPinsAndUpdatePath();
	}

	nOL.setPinDisplayPrompt();
};

nOL.promptForRemap = function (id, address) {
	var value = prompt("Update address to remap this pin.", unescape(address));
	if (value) nOL.remapPin(id, value);
};

nOL.promptForTag = function (id, tags) {
	var value = prompt(
		"Enter some descriptive words. These will be linked to a Google search.",
		unescape(tags),
	);
	if (value) nOL.tagPin(id, value);
};

nOL.promptForNotes = function (id, notes) {
	var value = prompt(
		"Add anything noteworthy. Write about the climactic scene that took place here, for example, or the real-life landmark a setting from the story was modeled on.",
		unescape(notes || ""),
	);
	if (value) nOL.annotatePin(id, value);
};

nOL.promptForBook = function (gLatLng, place, address) {
	var keywords = prompt(
		"Add a novel to the map. Our only requirement: that it be evocative of the place.\n\nEnter keywords describing the book: title, author, etc.",
		"",
	);
	if (keywords) nOL.findBook(gLatLng, place || "", address, keywords);
};

nOL.listenForDoubleClick = function () {
	nOL.clickingZooms = !nOL.clickingZooms; // negate effect of toggle
	nOL.toggleMapMode();
	nOL.setTitleAndPath(nOL.defaultTitle, "/");
};

nOL.toggleMapMode = function () {
	nOL.clickingZooms = !nOL.clickingZooms;

	if (nOL.clickingZooms) {
		if (nOL.clickListener != undefined)
			google.maps.event.removeListener(nOL.clickListener);
		$("#mode-button")[0].title = "Double-click map to zoom. Click to toggle";
		$("#mode-button")[0].value = "Mode: Zoom";
		nOL.map.setOptions({
			draggableCursor: "default",
			disableDoubleClickZoom: false,
		});
	} else {
		nOL.listenFor("dblclick", "nOL.promptForBook(e.latLng)");
		$("#mode-button")[0].title =
			"Double-click map to add pins. Click to toggle";
		$("#mode-button")[0].value = "Mode: Add Pins";
		nOL.map.setOptions({
			draggableCursor: "crosshair",
			disableDoubleClickZoom: true,
		});
	}
};

nOL.setPinDisplayPrompt = function () {
	$("#pin-display-button")[0].title = "Click to change pins displayed";

	if (nOL.pinType === 0) $("#pin-display-button")[0].value = "Pins: All";
	else if (nOL.pinType === 1)
		$("#pin-display-button")[0].value = "Pins: My Pins";
	else if (nOL.pinType === 2)
		$("#pin-display-button")[0].value = "Pins: Bookmarks";
	else if (nOL.pinType === 3)
		$("#pin-display-button")[0].value = "Pins: Friends";
};

nOL.setTitleAndPath = function (title, path) {
	document.title = title;
	if (history.pushState) history.pushState(null, title, path);
	nOL.updateShareButtons();
};

nOL.togglePinDisplay = function () {
	nOL.pinType += 1;

	if (
		(nOL.loggedIn() && nOL.pinType > 3) ||
		(!nOL.loggedIn() && nOL.pinType > 1)
	)
		nOL.pinType = 0;

	if (nOL.pinType === 0) nOL.showAllPinsAndUpdatePath();
	else if (nOL.pinType === 1) nOL.showMyPins();
	else if (nOL.pinType === 2) nOL.showBookmarks();
	else if (nOL.pinType === 3) nOL.showFriendsPins();

	nOL.setPinDisplayPrompt();
};

nOL.addPin = function (location) {
	if (location && location.lat_lng) {
		var latLng = nOL.toLatLng(location.lat_lng);
		var pin = new google.maps.Marker({
			draggable: location.writable,
			animation: google.maps.Animation.DROP,
			icon: {
				anchor: new google.maps.Point(2, 35),
				url: document.body.dataset.pinUrl,
			},
			position: latLng,
		});

		nOL.pins[location.id] = pin;

		google.maps.event.addListener(pin, "click", function () {
			nOL.setTitleAndPath(
				location.title + " - Novels: On Location",
				"/locations/" + location.slug,
			);
			nOL.openBalloon(location);
		});

		google.maps.event.addListener(pin, "dragend", function () {
			if (confirm("Move this pin?"))
				nOL.movePin(location.id, pin.getPosition());
			else pin.setPosition(latLng);
		});
	}
};

nOL.addPins = function (selectedLocationSlug) {
	for (var i = 0; i < nOL.locations.length; i++) {
		var location = nOL.locations[i];
		nOL.addPin(location);

		// is the pin writable but missing an fb id?
		if (
			nOL.fb_session &&
			location.writable &&
			location.user_id === undefined &&
			nOL.myLocation(location)
		) {
			nOL.claimPin(location.id);
		}

		if (selectedLocationSlug && location.slug === selectedLocationSlug) {
			nOL.openBalloon(location);
			nOL.zoomIn(nOL.toLatLng(location.lat_lng));
		}
	}
	if (nOL.anchorQuery) nOL.processAnchorQuery();
	else nOL.showAllPins();
};

nOL.shouldAddPin = function (googleResults) {
	var types = googleResults.types;
	var typesToPin = ["establishment", "point_of_interest", "street_address"];

	for (var i = 0; i < typesToPin.length; i++) {
		if ($.inArray(typesToPin[i], types)) return true;
	}

	return false;
};

nOL.hidePin = function (id) {
	if (nOL.pins[id]) nOL.pins[id].setMap(null);
};

nOL.hidePins = function () {
	for (var i = 0; i < nOL.locations.length; i++) {
		nOL.hidePin(nOL.locations[i].id);
	}
};

nOL.myBookmark = function (location) {
	return (
		location.bookmark_user_ids &&
		location.bookmark_user_ids.indexOf(nOL.fb_session.userID) != -1
	);
};

nOL.myFriendsLocation = function (location) {
	return $.inArray(location.user_id, nOL.friendIds) != -1;
};

nOL.myLocation = function (location) {
	return (
		$.cookie("user_token") === location.user_token ||
		(nOL.loggedIn() && location.user_id === nOL.fb_session.userID)
	);
};

nOL.remapPin = function (id, place) {
	nOL.geocoder.geocode({ address: place }, function (results, status) {
		if (status === google.maps.GeocoderStatus.OK) {
			r = results[0];
			nOL.zoomIn(r.geometry.location);

			if (nOL.shouldAddPin(r)) {
				$.ajax({
					type: "PUT",
					url: "/locations/" + id,
					data: {
						"location[address]": r.formatted_address,
						"location[latLng]": r.geometry.location.toUrlValue(),
						"location[tags]": place,
					},
				});
			}
		} else alert("Couldn't geocode! The error was " + status);
	});
};

nOL.removePin = function (id) {
	nOL.hidePin(id);
	delete nOL.pins[id];
};

nOL.replacePin = function (location) {
	nOL.removePin(location.id);
	nOL.locations.splice(nOL.locations.indexOf(location), 1);
	nOL.locations.push(location);
	nOL.addPin(location);
	nOL.showPin(location.id);
};

nOL.showAllPins = function () {
	nOL.bounds = new google.maps.LatLngBounds();
	for (var i = 0; i < nOL.locations.length; i++) {
		nOL.showPin(nOL.locations[i].id);
	}
	nOL.map.fitBounds(nOL.bounds);
};

nOL.showAllPinsAndUpdatePath = function () {
	nOL.showAllPins();
	nOL.setTitleAndPath(nOL.defaultTitle, "/");
};

nOL.showBookmarks = function () {
	nOL.bounds = new google.maps.LatLngBounds();
	for (var i = 0; i < nOL.locations.length; i++) {
		var location = nOL.locations[i];

		if (nOL.myBookmark(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	nOL.setTitleAndPath("Bookmarks - Novels: On Location", "/#!bookmarks");
};

nOL.showFriendsPins = function () {
	nOL.bounds = new google.maps.LatLngBounds();
	for (var i = 0; i < nOL.locations.length; i++) {
		var location = nOL.locations[i];

		if (nOL.myFriendsLocation(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	if (nOL.loggedIn())
		nOL.setTitleAndPath("Friends - Novels: On Location", "/#!friends");
};

nOL.showMyPins = function () {
	nOL.bounds = new google.maps.LatLngBounds();
	for (var i = 0; i < nOL.locations.length; i++) {
		var location = nOL.locations[i];

		if (nOL.myLocation(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	nOL.setTitleAndPath("My Pins - Novels: On Location", "/#!my");
};

nOL.showPin = function (id) {
	if (nOL.pins[id]) {
		nOL.pins[id].setMap(nOL.map);
		nOL.bounds.extend(nOL.pins[id].getPosition());
	}
};

nOL.showPins = function (keyword, path) {
	nOL.closeBalloon();
	if (keyword === "") nOL.showAllPinsAndUpdatePath();
	else {
		nOL.hidePins();
		nOL.bounds = new google.maps.LatLngBounds();
		const regex = new RegExp(unescape(keyword).trim(), "i");
		for (const location of nOL.locations) {
			if (
				regex.test(
					Reflect.get(location, anchorKindToLocationProperty[nOL.anchorKind]),
				)
			)
				nOL.showPin(location.id);
		}
		nOL.map.fitBounds(nOL.bounds);
		nOL.setTitleAndPath(
			keyword + " - Novels: On Location",
			path || "#!search-" + escape(keyword),
		);
	}
};

nOL.codePlace = function (input) {
	nOL.geocoder.geocode({ address: input }, function (results, status) {
		if (status === google.maps.GeocoderStatus.OK) {
			r = results[0];
			nOL.zoomIn(r.geometry.location);

			if (nOL.shouldAddPin(r))
				nOL.promptForBook(r.geometry.location, input, r.formatted_address);
		} else alert("Couldn't geocode! The error was " + status);
	});
};

nOL.zoomIn = function (gLatLng) {
	nOL.zoomer.getMaxZoomAtLatLng(gLatLng, function (response) {
		nOL.map.setCenter(gLatLng);

		if (response.status != google.maps.MaxZoomStatus.OK) {
			alert("Couldn't zoom!");
			nOL.map.setZoom(8);
			return;
		} else
			nOL.map.setZoom(
				nOL.map.getZoom() === response.zoom - 5
					? response.zoom - 3
					: response.zoom - 5,
			);
	});
};

nOL.zoomOut = function () {
	nOL.map.setZoom(nOL.checkOrientation() ? 3 : 2);
};

nOL.closeBalloon = function () {
	if (nOL.openWindow != undefined) nOL.openWindow.close();
};

nOL.openBalloon = function (location) {
	if (location.user_name === null) nOL.getFacebookName(location);
	nOL.closeBalloon();
	html = '<div class="map-balloon">';
	if (location.user_id === null && location.user_token === null)
		html +=
			"<input onClick=\"nOL.claimPin('" +
			location.id +
			'\')" type="button" value="Claim" title="Claim this pin"/>';
	if (location.writable)
		html +=
			"<input onClick=\"nOL.deletePin('" +
			location.id +
			'\')" type="button" value="Delete" title="Delete this pin"/><input onClick="nOL.promptForTag(\'' +
			location.id +
			"', '" +
			escape(location.tags) +
			'\')" type="button" value="Tag" title="Tag pin"/><input onClick="nOL.promptForRemap(\'' +
			location.id +
			"', '" +
			escape(location.address) +
			'\')" type="button" value="Remap" title="Remap pin"/>';
	if (nOL.fb_session) {
		if (nOL.myBookmark(location))
			html +=
				"<input onClick=\"nOL.unBookmarkPin('" +
				location.id +
				'\')" type="button" value="Un-Bookmark" title="Un-bookmark this pin"/>';
		else
			html +=
				"<input onClick=\"nOL.bookmarkPin('" +
				location.id +
				'\')" type="button" value="Bookmark" title="Bookmark this pin"/>';
	}
	if (location.writable)
		html +=
			"<input onClick=\"nOL.promptForNotes('" +
			location.id +
			"', '" +
			escape(location.notes || "") +
			'\')" type="button" value="Annotate" title="Annotate pin"/>';
	html +=
		'<input onClick="nOL.zoomIn(nOL.toLatLng([' +
		location.lat_lng +
		']))" type="button" value="Zoom" title="Zoom to pin"/>';
	if (location.image_url)
		html +=
			'<h1><a href="' +
			location.store_url +
			'" target="_blank"><img src="' +
			location.image_url +
			'" alt="Cover of ' +
			location.title +
			'" class="thumbnail" height=' +
			location.image_height +
			" width=" +
			location.image_width +
			">" +
			location.title +
			"</a></h1>";
	else
		html +=
			'<h1><a href="' +
			location.store_url +
			'" target="_blank">' +
			location.title +
			"</a></h1>";
	html +=
		'<h2>by <a href="https://en.wikipedia.org/wiki/' +
		encodeURI(location.author) +
		'" target="_blank">' +
		location.author +
		"</a></h2>";
	if (location.address) html += "<h2>" + location.address + "</h2>";
	if (location.review) html += '<p class="clear">' + location.review + "</p>";
	else html += "<p><em>No reviews found.</em></p>";
	if (location.notes)
		html += "<h3>Reader Notes</h3><p>" + location.notes + "</p>";
	if (location.itunes_id)
		html +=
			'<a class=store href="' +
			location.itunes_affiliate_url +
			'" target=_blank><img src="https://toolbox.marketingtools.apple.com/api/v2/badges/app-icon-books/standard/en-us" alt="Apple Books app icon" /></a>';
	html += "<br/>";
	if (location.user_id) {
		html +=
			'Added by <a href="https://www.facebook.com/profile.php?id=' +
			location.user_id +
			'" id="' +
			location.user_id +
			'" target="_blank">' +
			(location.user_name || "(loading...)") +
			"</a> on " +
			location.added_at_s;
	} else {
		html += "Added on " + location.added_at_s;
	}
	var authorPath = "/#!author-" + escape(location.author);
	var novelPath = "/#!novel-" + escape(location.title_for_regex);
	html +=
		'<br/><div class=search-links><a href="' +
		novelPath +
		'" onClick="nOL.showPins(\'' +
		location.title_for_regex +
		"', '" +
		novelPath +
		'\')" title="Show all locations for the novel ' +
		location.title +
		'">All Locations for Novel</a><span class=bullet>|</span><a href="' +
		authorPath +
		'" onClick="nOL.showPins(\'' +
		location.author +
		"', '" +
		authorPath +
		'\')" title="Show all novels by the author ' +
		location.author +
		'">All Novels by Author</a>';
	if (location.user_id) {
		var readerPath = "/#!reader-" + location.user_id;
		html +=
			'<span class=bullet>|</span><a href="' +
			readerPath +
			'" id=reader-link onClick="nOL.showPins(\'' +
			location.user_id +
			"', '" +
			readerPath +
			'\')" title="Show all pins added by this reader">All Pins by Reader</a>';
	}
	html += "</div>";
	if (location.tags) html += "Tags: " + nOL.tagLinks(location);
	html += "</p></div>";
	nOL.openWindow = new google.maps.InfoWindow({ content: html });
	nOL.openWindow.open(nOL.map, nOL.pins[location.id]);
	google.maps.event.addListener(nOL.openWindow, "closeclick", function () {
		nOL.listenForDoubleClick();
	});
	nOL.listenFor("click", "nOL.closeBalloon(); nOL.listenForDoubleClick()");
};

nOL.annotatePin = function (id, notes) {
	$.ajax({
		type: "PUT",
		url: "/locations/" + id,
		data: {
			"location[notes]": notes,
		},
	});
};

nOL.bookmarkPin = function (id) {
	$.ajax({
		type: "PUT",
		url: "/locations/" + id + "/bookmark",
	});
};

nOL.claimPin = function (id) {
	$.ajax({
		type: "PUT",
		url: "/locations/" + id,
		data: {
			caller: "claim",
			"location[user_id]": (nOL.fb_session && nOL.fb_session.userID) || null,
			"location[user_token]": $.cookie("user_token"),
		},
	});
};

nOL.createPin = function (latLng, place, address, keywords) {
	$.post("/locations", {
		"location[address]": address || "",
		"location[book_keywords]": keywords,
		"location[latLng]": nOL.toLatLng(latLng).toUrlValue(),
		"location[tags]": place,
		"location[user_id]": (nOL.fb_session && nOL.fb_session.userID) || null,
		"location[user_token]": $.cookie("user_token"),
	});
};

nOL.deletePin = function (id) {
	if (confirm("Are you sure? This action cannot be undone.")) {
		$.ajax({
			type: "DELETE",
			url: "/locations/" + id,
		});
	}
};

nOL.findBook = function (gLatLng, place, address, keywords) {
	$.get("/locations/new", {
		"location[address]": address || "",
		"location[tags]": place,
		"location[book_keywords]": keywords,
		"location[latLng]": gLatLng.toUrlValue(),
	});
};

nOL.getLocations = function (selectedLocationSlug) {
	$.get(
		"/locations.json",
		{ t: new Date().getTime(), user_token: $.cookie("user_token") },
		function (data) {
			nOL.locations = data;
			nOL.addPins(selectedLocationSlug);
		},
	);
};

nOL.movePin = function (id, gLatLng) {
	$.ajax({
		type: "PUT",
		url: "/locations/" + id,
		data: {
			"location[latLng]": gLatLng.toUrlValue(),
		},
	});
};

nOL.tagLinks = function (location) {
	var tags = $.map(location.tags.split(","), function (tag, i) {
		var tag = $.trim(tag);
		var tagPath = "/#!search-" + escape(tag);
		var link =
			'<a href="' +
			tagPath +
			'" onClick="nOL.showPins(\'' +
			escape(tag) +
			"', '" +
			tagPath +
			'\')" title="Show all locations with the tag ' +
			escape(tag) +
			'">' +
			tag +
			"</a>";
		return link;
	});
	return tags.join(", ");
};

nOL.tagPin = function (id, tags) {
	$.ajax({
		type: "PUT",
		url: "/locations/" + id,
		data: {
			"location[tags]": tags,
		},
	});
};

nOL.toLatLng = function (latLng) {
	return new google.maps.LatLng(latLng[0], latLng[1]);
};

nOL.unBookmarkPin = function (id) {
	$.ajax({
		type: "DELETE",
		url: "/locations/" + id + "/unbookmark",
	});
};

// Adapted from http://www.brandspankingnew.net/archive/2005/08/adding_an_os_x.html
var applesearch;
if (!applesearch) applesearch = {};

applesearch.init = function () {
	// add applesearch css for non-safari, dom-capable browsers
	if (
		navigator.userAgent.toLowerCase().indexOf("safari") < 0 &&
		document.getElementById
	) {
		this.clearBtn = false;
	}
};

// called when on user input - toggles clear fld btn
applesearch.onChange = function (fldID, btnID) {
	// check whether to show delete button
	var fld = document.getElementById(fldID);
	var btn = document.getElementById(btnID);
	if (fld.value.length > 0 && !this.clearBtn) {
		btn.fldID = fldID; // btn remembers it's field
		btn.onclick = this.clearBtnClick;
		this.clearBtn = true;
	} else if (fld.value.length === 0 && this.clearBtn) {
		btn.onclick = null;
		this.clearBtn = false;
	}
};

// clears field
applesearch.clearFld = function (fldID, btnID) {
	var fld = document.getElementById(fldID);
	fld.value = "";
	this.onChange(fldID, btnID);

	if (fldID === "book-input") {
		nOL.showPins($("#book-input")[0].value, true);
	}
};

// called by btn.onclick event handler - calls clearFld for this button
applesearch.clearBtnClick = function () {
	applesearch.clearFld(this.fldID, this.id);
};

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
jQuery.cookie = function (name, value, options) {
	if (typeof value != "undefined") {
		// name and value given, set cookie
		options = options || {};
		if (value === null) {
			value = "";
			options.expires = -1;
		}
		var expires = "";
		if (
			options.expires &&
			(typeof options.expires === "number" || options.expires.toUTCString)
		) {
			var date;
			if (typeof options.expires === "number") {
				date = new Date();
				date.setTime(date.getTime() + options.expires * 24 * 60 * 60 * 1000);
			} else {
				date = options.expires;
			}
			expires = "; expires=" + date.toUTCString(); // use expires attribute, max-age is not supported by IE
		}
		// CAUTION: Needed to parenthesize options.path and options.domain
		// in the following expressions, otherwise they evaluate to undefined
		// in the packed version for some reason...
		var path = options.path ? "; path=" + options.path : "";
		var domain = options.domain ? "; domain=" + options.domain : "";
		var secure = options.secure ? "; secure" : "";
		document.cookie = [
			name,
			"=",
			encodeURIComponent(value),
			expires,
			path,
			domain,
			secure,
		].join("");
	} else {
		// only name given, get cookie
		var cookieValue = null;
		if (document.cookie && document.cookie != "") {
			var cookies = document.cookie.split(";");
			for (var i = 0; i < cookies.length; i++) {
				var cookie = jQuery.trim(cookies[i]);
				// Does this cookie string begin with the name we want?
				if (cookie.substring(0, name.length + 1) === name + "=") {
					cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
					break;
				}
			}
		}
		return cookieValue;
	}
};
