// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// qlty-ignore: qlty:file-complexity
const searchTermToLocationProperty = {
	author: "author",
	novel: "title",
	place: "place",
	reader: "user_id",
	search: "terms",
};
const nOL = {};
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

nOL.searchQuery = () => {
	return unescape(window.location.hash.substring(2));
};
nOL.searchTerm = () => {
	return nOL.searchQuery().split("-")[0];
};
nOL.searchValue = () => {
	return nOL.searchQuery().split("-")[1] || nOL.searchTerm();
};

nOL.init = (settings) => {
	nOL.defaultTitle = settings.defaultTitle;
	nOL.host = settings.host;
	typeof FB !== "undefined" &&
		FB.init({
			appId: settings.fbAppId,
			cookie: true,
			status: true,
			version: "v2.11",
			xfbml: true,
		});
	typeof FB !== "undefined" &&
		FB.getLoginStatus((response) => {
			nOL.statusChangeCallback(response);
		});

	nOL.bounds = new google.maps.LatLngBounds();
	nOL.geocoder = new google.maps.Geocoder();
	nOL.map = new google.maps.Map(document.querySelector("#map-canvas"), {
		backgroundColor: "white",
		center: new google.maps.LatLng(0, 0),
		draggableCursor: "default",
		mapTypeId: google.maps.MapTypeId.HYBRID,
		minZoom: 2,
	});
	nOL.zoomer = new google.maps.MaxZoomService();
	nOL.getLocations(settings.selectedLocationSlug);

	// Set prompts
	document.querySelector("#book-input").value = nOL.bookPrompt;
	document.querySelector("#place-input").value = nOL.placePrompt;

	nOL.updateShareButtons();

	// Register event listeners
	document.querySelector("#book-input").addEventListener("blur", (e) => {
		const input = e.target;
		if (input.value === "") {
			input.value = nOL.bookPrompt;
			nOL.showAllPinsAndUpdatePath();
		}
		input.style.color = "#777";
		nOL.listenForShortcuts();
	});
	document.querySelector("#book-input").addEventListener("focus", (e) => {
		const input = e.target;
		if (input === nOL.bookPrompt) input.value = "";
		input.style.color = "black";
		nOL.dontListenForShortcuts();
	});
	document.querySelector("#book-input").addEventListener("keyup", () => {
		const keyword = document.querySelector("#book-input").value;
		nOL.showPins(keyword, `#!search-${escape(keyword)}`);
	});
	document.querySelector("#mode-button").addEventListener("click", () => {
		nOL.toggleMapMode;
	});
	document
		.querySelector("#pin-display-button")
		.addEventListener("click", () => {
			nOL.togglePinDisplay;
		});
	document.querySelector("#place-input").addEventListener("blur", (e) => {
		const input = e.target;
		input.value = nOL.placePrompt;
		input.style.color = "#777";
		nOL.listenForShortcuts();
	});
	document.querySelector("#place-input").addEventListener("focus", (e) => {
		const input = e.target;
		input.value = "";
		input.style.color = "black";
		nOL.dontListenForShortcuts();
	});
	document.querySelector("#place-input").addEventListener("keypress", (e) => {
		if ((e.keyCode || e.which) === 13)
			nOL.codePlace(document.querySelector("#place-input").value);
	});

	nOL.listenForLogin();
	nOL.listenForShortcuts();
	applesearch.init();

	if (settings.error) alert(settings.error);
};

nOL.statusChangeCallback = (response) => {
	if (response.status === "connected") {
		nOL.initSession(response.authResponse);
	} else {
		nOL.cookie("fb_id", null);
	}
};

nOL.initSession = (session) => {
	nOL.fb_session = session;
	nOL.cookie("fb_id", nOL.fb_session?.userID);
	nOL.setPinDisplayPrompt();
	nOL.getFriends();
};

nOL.checkOrientation = () => {
	let portrait = false;
	if (window.orientation !== null) portrait = Math.abs(orientation) !== 90;
	return portrait;
};

nOL.getFacebookName = (location) => {
	if (location.user_name === undefined && location.user_id) {
		typeof FB !== "undefined" &&
			FB.api(`/${location.user_id}`, (response) => {
				document.querySelector(`#${location.user_id}`).text(response.name);
				location.user_name = response.name;
			});
	}
};

nOL.getFriendIds = () => {
	for (let i = 0; i < nOL.friends.length; i++) {
		nOL.friendIds[i] = nOL.friends[i].id;
	}
};

nOL.getFriends = () => {
	typeof FB !== "undefined" &&
		FB.api("/me/friends", (response) => {
			nOL.friends = response.data;
			nOL.getFriendIds();
		});
};

nOL.updateFacebookLikeButton = () => {
	document.querySelector("#fb-like").dataset.href = document.URL;
};

nOL.updateShareButtons = () => {
	nOL.updateFacebookLikeButton();
	nOL.updateTweetButton();
};

nOL.updateTweetButton = () => {
	const iframe = document.querySelector("#tweet");
	iframe.src = iframe.src.replace(
		/\?.+/,
		`?related=${nOL.twitterAccount}&text=${nOL.sharingMessage}&url=${document.URL}`,
	);
};

nOL.listenFor = (event, args) => {
	if (nOL.clickListener !== undefined)
		google.maps.event.removeListener(nOL.clickListener);
	nOL.clickListener = google.maps.event.addListener(nOL.map, event, () => {
		// qlty-ignore: biome:lint/security/noGlobalEval
		eval(args);
	});
};

nOL.listenForLogin = () => {
	document.querySelector("#login-button").click(() => {
		nOL.toggleLogin();
	});
};

nOL.dontListenForShortcuts = () => {
	shortcut.remove("l");
	shortcut.remove("m");
	shortcut.remove("p");
};

nOL.listenForShortcuts = () => {
	shortcut.add("l", nOL.toggleLogin);
	shortcut.add("m", nOL.toggleMapMode);
	shortcut.add("p", nOL.togglePinDisplay);
};

nOL.loggedIn = () => !!nOL.cookie("fb_id");

nOL.logIn = () => {
	typeof FB !== "undefined" &&
		FB.login((response) => {
			console.log(response);
			if (response.authResponse) {
				nOL.initSession(response.authResponse);
				document.location.reload();
			} else {
				console.log("193");
			}
		});
};

nOL.logOut = () => {
	console.log("logOut");
	typeof FB !== "undefined" &&
		FB.logout(() => {
			nOL.cookie("fb_id", null);
			nOL.listenForLogin();
		});
	console.log(nOL.cookie("fb_id"));
	console.log("end");
};

nOL.toggleLogin = () => {
	nOL.loggedIn() ? nOL.logOut() : nOL.logIn();
};

nOL.processAnchorQuery = () => {
	switch (nOL.searchTerm()) {
		case "author":
			nOL.pinType = 0;
			nOL.showPins(nOL.searchValue(), window.location.hash);
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
			nOL.showPins(nOL.searchValue(), window.location.hash);
			break;
		case "place":
			nOL.pinType = 0;
			nOL.showPins(nOL.searchValue(), window.location.hash);
			break;
		case "reader":
			nOL.pinType = 0;
			nOL.showPins(nOL.searchValue(), window.location.hash);
			break;
		case "search":
			nOL.pinType = 0;
			nOL.showPins(nOL.searchValue(), window.location.hash);
			break;
		default:
			nOL.pinType = 0;
			nOL.showAllPinsAndUpdatePath();
	}

	nOL.setPinDisplayPrompt();
};

nOL.promptForRemap = (id, address) => {
	const value = prompt("Update address to remap this pin.", unescape(address));
	if (value) nOL.remapPin(id, value);
};

nOL.promptForTag = (id, tags) => {
	const value = prompt(
		"Enter some descriptive words. These will be linked to a Google search.",
		unescape(tags),
	);
	if (value) nOL.tagPin(id, value);
};

nOL.promptForNotes = (id, notes) => {
	const value = prompt(
		"Add anything noteworthy. Write about the climactic scene that took place here, for example, or the real-life landmark a setting from the story was modeled on.",
		unescape(notes || ""),
	);
	if (value) nOL.annotatePin(id, value);
};

nOL.promptForBook = (gLatLng, place, address) => {
	const keywords = prompt(
		"Add a novel to the map. Our only requirement: that it be evocative of the place.\n\nEnter keywords describing the book: title, author, etc.",
		"",
	);
	if (keywords) nOL.findBook(gLatLng, place || "", address, keywords);
};

nOL.listenForDoubleClick = () => {
	nOL.clickingZooms = !nOL.clickingZooms; // negate effect of toggle
	nOL.toggleMapMode();
	nOL.setTitleAndPath(nOL.defaultTitle, "/");
};

nOL.toggleMapMode = () => {
	nOL.clickingZooms = !nOL.clickingZooms;

	if (nOL.clickingZooms) {
		if (nOL.clickListener !== undefined)
			google.maps.event.removeListener(nOL.clickListener);
		document.querySelector("#mode-button").title =
			"Double-click map to zoom. Click to toggle";
		document.querySelector("#mode-button").value = "Mode: Zoom";
		nOL.map.setOptions({
			draggableCursor: "default",
			disableDoubleClickZoom: false,
		});
	} else {
		nOL.listenFor("dblclick", "nOL.promptForBook(e.latLng)");
		document.querySelector("#mode-button").title =
			"Double-click map to add pins. Click to toggle";
		document.querySelector("#mode-button").value = "Mode: Add Pins";
		nOL.map.setOptions({
			draggableCursor: "crosshair",
			disableDoubleClickZoom: true,
		});
	}
};

nOL.setPinDisplayPrompt = () => {
	document.querySelector("#pin-display-button").title =
		"Click to change pins displayed";

	if (nOL.pinType === 0)
		document.querySelector("#pin-display-button").value = "Pins: All";
	else if (nOL.pinType === 1)
		document.querySelector("#pin-display-button").value = "Pins: My Pins";
	else if (nOL.pinType === 2)
		document.querySelector("#pin-display-button").value = "Pins: Bookmarks";
	else if (nOL.pinType === 3)
		document.querySelector("#pin-display-button").value = "Pins: Friends";
};

nOL.setTitleAndPath = (title, path) => {
	document.title = title;
	if (history.pushState) history.pushState(null, title, path);
	nOL.updateShareButtons();
};

nOL.togglePinDisplay = () => {
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

nOL.addPin = (location) => {
	if (location?.lat_lng) {
		const latLng = nOL.toLatLng(location.lat_lng);
		const pin = new google.maps.Marker({
			draggable: location.writable,
			animation: google.maps.Animation.DROP,
			icon: {
				anchor: new google.maps.Point(2, 35),
				url: document.body.dataset.pinUrl,
			},
			position: latLng,
		});

		nOL.pins[location.id] = pin;

		google.maps.event.addListener(pin, "click", () => {
			nOL.setTitleAndPath(
				`${location.title} - Novels: On Location`,
				`/locations/${location.slug}`,
			);
			nOL.openBalloon(location);
		});

		google.maps.event.addListener(pin, "dragend", () => {
			if (confirm("Move this pin?"))
				nOL.movePin(location.id, pin.getPosition());
			else pin.setPosition(latLng);
		});
	}
};

nOL.addPins = (selectedLocationSlug) => {
	for (let i = 0; i < nOL.locations.length; i++) {
		const location = nOL.locations[i];
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
	if (nOL.searchValue()) nOL.processAnchorQuery();
	else nOL.showAllPins();
};

nOL.shouldAddPin = (googleResults) => {
	const types = googleResults.types;
	const typesToPin = ["establishment", "point_of_interest", "street_address"];

	for (let i = 0; i < typesToPin.length; i++) {
		if (types.includes(typesToPin[i])) return true;
	}

	return false;
};

nOL.hidePin = (id) => {
	if (nOL.pins[id]) nOL.pins[id].setMap(null);
};

nOL.hidePins = () => {
	for (let i = 0; i < nOL.locations.length; i++) {
		nOL.hidePin(nOL.locations[i].id);
	}
};

nOL.myBookmark = (location) => {
	return (
		location.bookmark_user_ids &&
		location.bookmark_user_ids.includes(nOL.fb_session?.userID)
	);
};

nOL.myFriendsLocation = (location) => {
	return nOL.friendIds.includes(location.user_id);
};

nOL.myLocation = (location) => {
	return (
		nOL.cookie("user_token") === location.user_token ||
		(nOL.loggedIn() && location.user_id === nOL.fb_session?.userID)
	);
};

nOL.remapPin = (id, place) => {
	nOL.geocoder.geocode({ address: place }, (results, status) => {
		if (status === google.maps.GeocoderStatus.OK) {
			r = results[0];
			nOL.zoomIn(r.geometry.location);

			if (nOL.shouldAddPin(r)) {
				$.ajax({
					type: "PUT",
					url: `/locations/${id}`,
					data: {
						"location[address]": r.formatted_address,
						"location[latLng]": r.geometry.location.toUrlValue(),
						"location[tags]": place,
					},
				});
			}
		} else alert(`Couldn't geocode! The error was ${status}`);
	});
};

nOL.removePin = (id) => {
	nOL.hidePin(id);
	delete nOL.pins[id];
};

nOL.replacePin = (location) => {
	nOL.removePin(location.id);
	nOL.locations.splice(nOL.locations.indexOf(location), 1);
	nOL.locations.push(location);
	nOL.addPin(location);
	nOL.showPin(location.id);
};

nOL.showAllPins = () => {
	nOL.bounds = new google.maps.LatLngBounds();
	for (let i = 0; i < nOL.locations.length; i++) {
		nOL.showPin(nOL.locations[i].id);
	}
	nOL.map.fitBounds(nOL.bounds);
};

nOL.showAllPinsAndUpdatePath = () => {
	nOL.showAllPins();
	nOL.setTitleAndPath(nOL.defaultTitle, "/");
};

nOL.showBookmarks = () => {
	nOL.bounds = new google.maps.LatLngBounds();
	for (let i = 0; i < nOL.locations.length; i++) {
		const location = nOL.locations[i];

		if (nOL.myBookmark(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	nOL.setTitleAndPath("Bookmarks - Novels: On Location", "/#!bookmarks");
};

nOL.showFriendsPins = () => {
	nOL.bounds = new google.maps.LatLngBounds();
	for (let i = 0; i < nOL.locations.length; i++) {
		const location = nOL.locations[i];

		if (nOL.myFriendsLocation(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	if (nOL.loggedIn())
		nOL.setTitleAndPath("Friends - Novels: On Location", "/#!friends");
};

nOL.showMyPins = () => {
	nOL.bounds = new google.maps.LatLngBounds();
	for (let i = 0; i < nOL.locations.length; i++) {
		const location = nOL.locations[i];

		if (nOL.myLocation(location)) nOL.showPin(location.id);
		else nOL.hidePin(location.id);
	}
	nOL.map.fitBounds(nOL.bounds);
	nOL.setTitleAndPath("My Pins - Novels: On Location", "/#!my");
};

nOL.showPin = (id) => {
	if (nOL.pins[id]) {
		nOL.pins[id].setMap(nOL.map);
		nOL.bounds.extend(nOL.pins[id].getPosition());
	}
};

nOL.showPins = (keyword, path) => {
	nOL.closeBalloon();
	if (keyword === "") nOL.showAllPinsAndUpdatePath();
	else {
		nOL.setTitleAndPath(
			`${keyword} - Novels: On Location`,
			path || `#!search-${escape(keyword)}`,
		);
		nOL.hidePins();
		nOL.bounds = new google.maps.LatLngBounds();
		const regex = new RegExp(unescape(keyword).trim(), "i");
		for (const location of nOL.locations) {
			if (
				regex.test(
					Reflect.get(location, searchTermToLocationProperty[nOL.searchTerm()]),
				)
			)
				nOL.showPin(location.id);
		}
		nOL.map.fitBounds(nOL.bounds);
	}
};

nOL.codePlace = (input) => {
	nOL.geocoder.geocode({ address: input }, (results, status) => {
		if (status === google.maps.GeocoderStatus.OK) {
			r = results[0];
			nOL.zoomIn(r.geometry.location);

			if (nOL.shouldAddPin(r))
				nOL.promptForBook(r.geometry.location, input, r.formatted_address);
		} else alert(`Couldn't geocode! The error was ${status}`);
	});
};

nOL.zoomIn = (gLatLng) => {
	nOL.zoomer.getMaxZoomAtLatLng(gLatLng, (response) => {
		nOL.map.setCenter(gLatLng);

		if (response.status !== google.maps.MaxZoomStatus.OK) {
			alert("Couldn't zoom!");
			nOL.map.setZoom(8);
			return;
		}
		nOL.map.setZoom(
			nOL.map.getZoom() === response.zoom - 5
				? response.zoom - 3
				: response.zoom - 5,
		);
	});
};

nOL.zoomOut = () => {
	nOL.map.setZoom(nOL.checkOrientation() ? 3 : 2);
};

nOL.closeBalloon = () => {
	if (nOL.openWindow !== undefined) nOL.openWindow.close();
};

// qlty-ignore: qlty:function-complexity
nOL.openBalloon = (location) => {
	if (location.user_name === null) nOL.getFacebookName(location);
	nOL.closeBalloon();
	html = '<div class="map-balloon">';
	if (location.user_id === null && location.user_token === null)
		html += `<input onClick="nOL.claimPin('${location.id}')" type="button" value="Claim" title="Claim this pin"/>`;
	if (location.writable)
		html += `<input onClick="nOL.deletePin('${location.id}')" type="button" value="Delete" title="Delete this pin"/><input onClick="nOL.promptForTag('${location.id}', '${escape(location.tags)}')" type="button" value="Tag" title="Tag pin"/><input onClick="nOL.promptForRemap('${location.id}', '${escape(location.address)}')" type="button" value="Remap" title="Remap pin"/>`;
	if (nOL.fb_session) {
		if (nOL.myBookmark(location))
			html += `<input onClick="nOL.unBookmarkPin('${location.id}')" type="button" value="Un-Bookmark" title="Un-bookmark this pin"/>`;
		else
			html += `<input onClick="nOL.bookmarkPin('${location.id}')" type="button" value="Bookmark" title="Bookmark this pin"/>`;
	}
	if (location.writable)
		html += `<input onClick="nOL.promptForNotes('${location.id}', '${escape(location.notes || "")}')" type="button" value="Annotate" title="Annotate pin"/>`;
	html += `<input onClick="nOL.zoomIn(nOL.toLatLng([${location.lat_lng}]))" type="button" value="Zoom" title="Zoom to pin"/>`;
	if (location.image_url)
		html += `<h1><a href="${location.store_url}" target="_blank"><img src="${location.image_url}" alt="Cover of ${location.title}" class="thumbnail" height=${location.image_height} width="${location.image_width}">${location.title}</a></h1>`;
	else
		html += `<h1><a href="${location.store_url}" target="_blank">${location.title}</a></h1>`;
	html += `<h2>by <a href="https://en.wikipedia.org/wiki/${encodeURI(location.author)}" target="_blank">${location.author}</a></h2>`;
	if (location.address) html += `<h2>${location.address}</h2>`;
	if (location.review) html += `<p class="clear">${location.review}</p>`;
	else html += "<p><em>No reviews found.</em></p>";
	if (location.notes) html += `<h3>Reader Notes</h3><p>${location.notes}</p>`;
	if (location.itunes_id)
		html += `<a class=store href="${location.itunes_affiliate_url}" target=_blank><img src="https://toolbox.marketingtools.apple.com/api/v2/badges/app-icon-books/standard/en-us" alt="Apple Books app icon" /></a>`;
	html += "<br/>";
	if (location.user_id) {
		html += `Added by <a href="https://www.facebook.com/profile.php?id=${location.user_id}" id="${location.user_id}" target="_blank">${location.user_name || "(loading...)"}</a> on ${location.added_at_s}`;
	} else {
		html += `Added on ${location.added_at_s}`;
	}
	const authorPath = `/#!author-${escape(location.author)}`;
	const novelPath = `/#!novel-${escape(location.title_for_regex)}`;
	html += `<br/><div class=search-links><a href="${novelPath}" onClick="nOL.showPins('${location.title_for_regex}', '${novelPath}')" title="Show all locations for the novel ${location.title}">All Locations for Novel</a><span class=bullet>|</span><a href="${authorPath}" onClick="nOL.showPins('${location.author}', '${authorPath}')" title="Show all novels by the author ${location.author}">All Novels by Author</a>`;
	if (location.user_id) {
		const readerPath = `/#!reader-${location.user_id}`;
		html += `<span class=bullet>|</span><a href="${readerPath}" id=reader-link onClick="nOL.showPins('${location.user_id}', '${readerPath}')" title="Show all pins added by this reader">All Pins by Reader</a>`;
	}
	html += "</div>";
	if (location.tags) html += `Tags: ${nOL.tagLinks(location)}`;
	html += "</p></div>";
	nOL.openWindow = new google.maps.InfoWindow({ content: html });
	nOL.openWindow.open(nOL.map, nOL.pins[location.id]);
	google.maps.event.addListener(nOL.openWindow, "closeclick", () => {
		nOL.listenForDoubleClick();
	});
	nOL.listenFor("click", "nOL.closeBalloon(); nOL.listenForDoubleClick()");
};

nOL.annotatePin = (id, notes) => {
	$.ajax({
		type: "PUT",
		url: `/locations/${id}`,
		data: {
			"location[notes]": notes,
		},
	});
};

nOL.bookmarkPin = (id) => {
	$.ajax({
		type: "PUT",
		url: `/locations/${id}/bookmark`,
	});
};

nOL.claimPin = (id) => {
	$.ajax({
		type: "PUT",
		url: `/locations/${id}`,
		data: {
			caller: "claim",
			"location[user_id]": nOL?.fb_session?.userID || null,
			"location[user_token]": nOL.cookie("user_token"),
		},
	});
};

nOL.createPin = (latLng, place, address, keywords) => {
	$.post("/locations", {
		"location[address]": address || "",
		"location[book_keywords]": keywords,
		"location[latLng]": nOL.toLatLng(latLng).toUrlValue(),
		"location[tags]": place,
		"location[user_id]": nOL?.fb_session?.userID || null,
		"location[user_token]": nOL.cookie("user_token"),
	});
};

nOL.deletePin = (id) => {
	if (confirm("Are you sure? This action cannot be undone.")) {
		$.ajax({
			type: "DELETE",
			url: `/locations/${id}`,
		});
	}
};

nOL.findBook = (gLatLng, place, address, keywords) => {
	$.get("/locations/new", {
		"location[address]": address || "",
		"location[tags]": place,
		"location[book_keywords]": keywords,
		"location[latLng]": gLatLng.toUrlValue(),
	});
};

nOL.getLocations = (selectedLocationSlug) => {
	$.get(
		"/locations.json",
		{ t: Date.now(), user_token: nOL.cookie("user_token") },
		(data) => {
			nOL.locations = data;
			nOL.addPins(selectedLocationSlug);
		},
	);
};

nOL.movePin = (id, gLatLng) => {
	$.ajax({
		type: "PUT",
		url: `/locations/${id}`,
		data: {
			"location[latLng]": gLatLng.toUrlValue(),
		},
	});
};

nOL.tagLinks = (location) => {
	const tags = $.map(location.tags.split(","), (tag) => {
		const trimmedTag = $.trim(tag);
		const tagPath = `/#!search-${escape(trimmedTag)}`;
		const link = `<a href="${tagPath}" onClick="nOL.showPins('${escape(trimmedTag)}', '${tagPath}')" title="Show all locations with the tag ${trimmedTag}">${trimmedTag}</a>`;
		return link;
	});
	return tags.join(", ");
};

nOL.tagPin = (id, tags) => {
	$.ajax({
		type: "PUT",
		url: `/locations/${id}`,
		data: {
			"location[tags]": tags,
		},
	});
};

nOL.toLatLng = (latLng) => {
	return new google.maps.LatLng(latLng[0], latLng[1]);
};

nOL.unBookmarkPin = (id) => {
	$.ajax({
		type: "DELETE",
		url: `/locations/${id}/unbookmark`,
	});
};

// Adapted from http://www.brandspankingnew.net/archive/2005/08/adding_an_os_x.html
let applesearch;
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
	const fld = document.getElementById(fldID);
	const btn = document.getElementById(btnID);
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
	const fld = document.getElementById(fldID);
	fld.value = "";
	this.onChange(fldID, btnID);

	if (fldID === "book-input") {
		nOL.showPins(document.querySelector("#book-input").value, true);
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
 * @example nOL.cookie('the_cookie', 'the_value');
 * @desc Set the value of a cookie.
 * @example nOL.cookie('the_cookie', 'the_value', { expires: 7, path: '/', domain: 'jquery.com', secure: true });
 * @desc Create a cookie with all available options.
 * @example nOL.cookie('the_cookie', 'the_value');
 * @desc Create a session cookie.
 * @example nOL.cookie('the_cookie', null);
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
 * @name nOL.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */

/**
 * Get the value of a cookie with the given name.
 *
 * @example nOL.cookie('the_cookie');
 * @desc Get the value of a cookie.
 *
 * @param String name The name of the cookie.
 * @return The value of the cookie.
 * @type String
 *
 * @name nOL.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */
// qlty-ignore: qlty:function-complexity
// qlty-ignore: biome:lint/suspicious/noAssignInExpressions
nOL.cookie = (name, value, options) => {
	if (typeof value !== "undefined") {
		// name and value given, set cookie
		options = options || {};
		if (value === null) {
			value = "";
			options.expires = -1;
		}
		let expires = "";
		if (
			options.expires &&
			(typeof options.expires === "number" || options.expires.toUTCString)
		) {
			let date;
			if (typeof options.expires === "number") {
				date = new Date();
				date.setTime(date.getTime() + options.expires * 24 * 60 * 60 * 1000);
			} else {
				date = options.expires;
			}
			expires = `; expires=${date.toUTCString()}`; // use expires attribute, max-age is not supported by IE
		}
		// CAUTION: Needed to parenthesize options.path and options.domain
		// in the following expressions, otherwise they evaluate to undefined
		// in the packed version for some reason...
		const path = options.path ? `; path=${options.path}` : "";
		const domain = options.domain ? `; domain=${options.domain}` : "";
		const secure = options.secure ? "; secure" : "";
		// qlty-ignore: biome:lint/suspicious/noDocumentCookie
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
		let cookieValue = null;
		if (document.cookie && document.cookie !== "") {
			const cookies = document.cookie.split(";");
			for (let i = 0; i < cookies.length; i++) {
				const cookie = String.prototype.trim(cookies[i]);
				// Does this cookie string begin with the name we want?
				if (cookie.substring(0, name.length + 1) === `${name}=`) {
					cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
					break;
				}
			}
		}
		return cookieValue;
	}
};
