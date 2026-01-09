(function () {
  const nav = document.getElementById("site-navigation");
  const toggle = document.getElementById("site-menu-toggle");

  if (!nav || !toggle || !("showPopover" in HTMLElement.prototype)) {
	return;
  }

  let lastFocused = null;

  function getFocusable(container) {
	return container.querySelectorAll(
	  'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
	);
  }

  function trapFocus(event) {
	if (event.key !== "Tab") return;

	const focusables = getFocusable(nav);
	if (!focusables.length) return;

	const first = focusables[0];
	const last = focusables[focusables.length - 1];

	if (event.shiftKey) {
	  if (document.activeElement === first) {
		event.preventDefault();
		last.focus();
	  }
	} else {
	  if (document.activeElement === last) {
		event.preventDefault();
		first.focus();
	  }
	}
  }

  nav.addEventListener("toggle", (event) => {
	if (event.newState === "open") {
	  lastFocused = document.activeElement;

	  const focusables = getFocusable(nav);
	  if (focusables.length) {
		focusables[0].focus();
	  }

	  nav.addEventListener("keydown", trapFocus);
	  toggle.setAttribute("aria-expanded", "true");
	}

	if (event.newState === "closed") {
	  nav.removeEventListener("keydown", trapFocus);

	  if (lastFocused) {
		lastFocused.focus();
	  }

	  toggle.setAttribute("aria-expanded", "false");
	}
  });
})();

(function () {
  "use strict";

  function initSplashBounce() {
	var el = document.querySelector(".splash-down-link img");
	if (!el) return;

	function runBounce() {
	  // Remove to restart animation cleanly
	  el.classList.remove("bounce-run");

	  // Force reflow so the browser recognizes a “fresh” animation start
	  void el.offsetWidth;

	  // Add bounce animation
	  el.classList.add("bounce-run");

	  // Duration 1.6s × 5 iterations = 8s total
	  // + 7s pause before next run
	  setTimeout(runBounce, (1.6 * 5 * 1000) + 7000);
	}

	runBounce();
  }

  if (document.readyState === "loading") {
	document.addEventListener("DOMContentLoaded", initSplashBounce);
  } else {
	initSplashBounce();
  }
})();

(function () {
  "use strict";

  function initNavOpacity() {
	var nav = document.querySelector("header");
	if (!nav) return;

	var threshold = 40; // px

	function updateNavOpacity() {
	  if (window.scrollY > threshold) {
		nav.classList.add("header-transparent");
	  } else {
		nav.classList.remove("header-transparent");
	  }
	}

	// Run immediately in case the user reloads while scrolled down
	updateNavOpacity();

	window.addEventListener("scroll", updateNavOpacity, { passive: true });
  }

  // Make sure the DOM is ready before querying .nav-wrapper
  if (document.readyState === "loading") {
	document.addEventListener("DOMContentLoaded", initNavOpacity);
  } else {
	initNavOpacity();
  }
})();

(function () {
  "use strict";

  function isInViewport(el) {
	var rect = el.getBoundingClientRect();
	var vh = window.innerHeight || document.documentElement.clientHeight;
	return rect.top < vh && rect.bottom > 0;
  }

  function initFadeSelected() {
	var main = document.querySelector("main");
	if (!main) return;

	// Only headings and images inside <main>
	var elements = main.querySelectorAll(
	  "h1, h2, h3, h4, h5, h6, img, div"
	);

	if (!elements.length) return;

	// Honour reduced-motion
	var prefersReducedMotion =
	  window.matchMedia &&
	  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

	if (prefersReducedMotion) {
	  elements.forEach(function (el) {
		el.classList.remove("fade-up-init", "fade-up-visible");
	  });
	  return;
	}

	var toObserve = [];

	elements.forEach(function (el) {
	  if (isInViewport(el)) {
		// Already visible on load – no animation
		el.classList.remove("fade-up-init", "fade-up-visible");
	  } else {
		// Prepare for reveal animation
		el.classList.add("fade-up-init");
		toObserve.push(el);
	  }
	});

	if (!toObserve.length) return;

	// No IntersectionObserver support = reveal immediately
	if (!("IntersectionObserver" in window)) {
	  toObserve.forEach(function (el) {
		el.classList.add("fade-up-visible");
	  });
	  return;
	}

	var observer = new IntersectionObserver(
	  function (entries, obs) {
		entries.forEach(function (entry) {
		  if (!entry.isIntersecting) return;

		  entry.target.classList.add("fade-up-visible");
		  obs.unobserve(entry.target); // animate once only
		});
	  },
	  {
		root: null,
		threshold: 0.2
	  }
	);

	toObserve.forEach(function (el) {
	  observer.observe(el);
	});
  }

  if (document.readyState === "loading") {
	document.addEventListener("DOMContentLoaded", initFadeSelected);
  } else {
	initFadeSelected();
  }
})();


//IIFE for UX code pux.js to avoid global namespace problems
(function() {
	// Function to update aria-expanded based on viewport width
	function updateAriaExpanded() {
		const navigation = document.getElementById('site-navigation');
		const hamburgerNav = document.getElementById('hamburger-nav');

		if (hamburgerNav && hamburgerNav.getAttribute('aria-expanded') === 'true') {
			navigation.setAttribute('aria-expanded', 'true');
		} else {
			navigation.setAttribute('aria-expanded', window.innerWidth >= 768 ? 'true' : 'false');
		}
	}
	// Function to toggle a specified attribute between two values
	function toggleAttribute(selector, attribute, value1, value2) {
		// Select the element
		const elem = document.querySelector(selector);

		// Get the current value of the attribute
		const currentValue = elem.getAttribute(attribute);

		// Set the attribute to the opposite value
		elem.setAttribute(attribute, currentValue === value1 ? value2 : value1);
	}

	// Function to toggle the attributes of the navigation elements when clicked
	function attributeToggler(e) {
		// Toggle data-state attribute between "closed" and "open"
		toggleAttribute("#mobile-nav-banner", "data-state", "closed", "open");
		toggleAttribute("#site-header", "data-state", "closed", "open");

		// Toggle aria-expanded attribute between "false" and "true"
		toggleAttribute("#hamburger-nav", "aria-expanded", "false", "true");

		// Add site-navigation element to toggle data-state and aria-expanded attributes
		toggleAttribute("#site-navigation", "aria-expanded", "false", "true");

		// Prevent default action of the click event
		e.preventDefault();
	}

	// Function to add event listeners to all navigation toggle elements
	function handleTogglers() {
		// Select all elements with class ".mobile-nav-toggle"
		const togglers = document.querySelectorAll(".mobile-nav-toggle");

		// Attach a click event listener to each toggle element
		function clickHandler(e) {
			attributeToggler(e);
		}

		togglers.forEach(function(toggler) {
			toggler.addEventListener("click", clickHandler);
		});
	}

	function addScrollButton() {
	  // Select the first h2 element
	  const h2Element = document.querySelector('h2');

	  // Select the scroll-to-top link
	  const scrollToTopLink = document.querySelector('.scroll-to-top');

	  // Set aria-hidden to true on page load
	  scrollToTopLink.setAttribute('aria-hidden', 'true');

	  // Define options for the Intersection Observer
	  const options = {
		threshold: 0.25 // Adjust the threshold value as needed
	  };

	  // Define the callback function
	  function callback(entries, observer) {
		entries.forEach(function(entry) {
		  if (entry.target === h2Element && entry.isIntersecting) {
			// First h2 element is visible, hide the scroll-to-top link
			scrollToTopLink.style.opacity = '0';
			scrollToTopLink.setAttribute('aria-hidden', 'true');
		  } else {
			// First h2 element is not visible, show the scroll-to-top link
			scrollToTopLink.style.opacity = '1';
			scrollToTopLink.setAttribute('aria-hidden', 'false');
		  }
		});
	  }

	  // Create a new Intersection Observer
	  const observer = new IntersectionObserver(callback, options);

	  // Start observing the h2 element
	if(h2Element){
		observer.observe(h2Element);
	}
	}

	// Function to hide and show the header based on scroll direction
	// An immediately-invoked function expression (IIFE) to avoid polluting the global namespace.
	function headerShowHide() {
		// Cache the header element to avoid repeatedly querying the DOM in the scroll event handler.
		const header = document.getElementById('site-header');

		// Check if the header element has the class 'show-hide'
		if (!header || !header.classList.contains('show-hide')) {
			return; // Exit the function if the header does not have the 'show-hide' class
		}


		// Debounce function to limit the rate at which a function can fire.
		function debounce(func, wait = 10, immediate = true) {
			// Declare a variable for the timeout.
			let timeout;

			// This is the function that will be called when debounced.
			function debounced() {
				// Capture the context (this) and arguments of the function that will be debounced.
				let context = this,
					args = arguments;

				// Function to be called after the delay. If 'immediate' is false,
				// call the debounced function.
				function later() {
					// Reset timeout to null when the wait time is over.
					timeout = null;

					// Call the function if immediate is false.
					// This will execute the function after wait time if immediate is false.
					if (!immediate) func.apply(context, args);
				}

				// If 'immediate' is true and there's no pending timeout,
				// call the function and start the wait time.
				let callNow = immediate && !timeout;

				// If a timeout is pending, clear it. This resets the timer.
				clearTimeout(timeout);

				// Start waiting by setting the timeout.
				timeout = setTimeout(later, wait);

				// If 'immediate' is true and there was no timeout pending,
				// call the function immediately without waiting.
				if (callNow) func.apply(context, args);
			}

			return debounced;
		}

		// This variable keeps track of the last scroll position.
		let lastScrollTop = 0;

		// Add a debounced event listener to the window object for scroll events.
		window.addEventListener('scroll', debounce(function() {
			// Get the current scroll position.
			let st = window.pageYOffset || document.documentElement.scrollTop;

			// If the current scroll position is greater than the last scroll position,
			// the user is scrolling down, so set the class of the header to 'closed'.
			if (st > lastScrollTop) {
				header.className = 'closed';
			} else {
				// If the current scroll position is not greater than the last scroll position,
				// the user is scrolling up, so set the class of the header to 'open'.
				header.className = 'open';
			}

			// Update lastScrollTop to the current scroll position,
			// or reset to 0 if the user has scrolled to the very top of the page.
			lastScrollTop = st <= 0 ? 0 : st;
		}), false);
	}

// Main function for controlling the lightbox dialog.
	function dialogLightBox() {
		// Retrieve necessary elements from the DOM.
		const lightboxGrid = document.querySelector('.lightbox-grid');
		if (!lightboxGrid) return; // If there's no lightboxGrid, don't proceed further

		const dialog = document.getElementById('lightbox-dialog');
		if (!dialog) return; // If there's no dialog, don't proceed further

		const lightboxImage = document.getElementById('lightbox-image');
		const lightboxCaption = document.getElementById('lightbox-caption');
		const lightboxCounter = document.getElementById('lightbox-counter');
		const figures = document.querySelectorAll('.lightbox-figure');
		if (!figures.length) return; // If there are no figures, don't proceed further

		let currentFigureIndex = 0;

// Map each figure to an object containing its relevant data.
		const figureData = Array.from(figures).map((figure) => {
			const img = figure.querySelector('img');
			const link = figure.querySelector('a.original-image');
			const caption = figure.querySelector('span.caption-text');
			let captionText = ""; // Initialize captionText as an empty string
			if (caption) { // If caption exists (is not null), get its textContent
				captionText = caption.textContent;
			}
			return {
				src: img.src,
				alt: img.alt,
				class: img.className,                          // Capture class
				width: img.getAttribute('width'),               // Get inline width attribute
				height: img.getAttribute('height'),             // Get inline height attribute
				link: link.outerHTML,                           // Store the entire HTML of the link
				caption: captionText                            // Store the cleaned-up caption text
			};
		});

		// Update the dialog with data from the figure at the given index.
		function updateDialog(index) {
			lightboxImage.src = figureData[index].src;
			lightboxImage.alt = figureData[index].alt;
			lightboxImage.className = figureData[index].class;   // Set class
			lightboxImage.setAttribute('width', figureData[index].width);  // Set width
			lightboxImage.setAttribute('height', figureData[index].height); // Set height
			lightboxCaption.innerHTML = figureData[index].caption + figureData[index].link;
			lightboxCounter.textContent = `Viewing figure ${index + 1} of ${figureData.length}`;
		}




		// Event delegation for figures.
		lightboxGrid.addEventListener('click', function(event) {
			const figure = event.target.closest('.lightbox-figure');
			if (figure) {
				currentFigureIndex = Array.from(figures).indexOf(figure);
				updateDialog(currentFigureIndex);
				document.body.style.overflow = 'hidden'; // Prevent scrolling when dialog is open.
				dialog.showModal();
				nextButton.focus(); // Set focus on the next button after the dialog is shown.
			}
		});

		// Previous button event handler.
		const prevButton = document.getElementById('prev-button');
		if (prevButton) { // Check if the prevButton exists
			prevButton.addEventListener('click', () => {
				if (currentFigureIndex > 0) {
					currentFigureIndex--;
					updateDialog(currentFigureIndex);
				}
			});
		}

		// Next button event handler.
		const nextButton = document.getElementById('next-button');
		if (nextButton) { // Check if the nextButton exists
			nextButton.addEventListener('click', () => {
				if (currentFigureIndex < figureData.length - 1) {
					currentFigureIndex++;
					updateDialog(currentFigureIndex);
				}
			});
		}

		// Close button event handler.
		const closeButton = document.getElementById('close-lightbox');
		if (closeButton) { // Check if the closeButton exists
			closeButton.addEventListener('click', () => {
				dialog.close();
				document.body.style.overflow = ''; // Allow scrolling again when dialog is closed.
			});
		}

		// Keyboard navigation handlers.
		window.addEventListener('keydown', function(event) {
			switch (event.key) {
				case 'ArrowLeft':
					if (currentFigureIndex > 0) {
						currentFigureIndex--;
						updateDialog(currentFigureIndex);
					}
					break;
				case 'ArrowRight':
					if (currentFigureIndex < figureData.length - 1) {
						currentFigureIndex++;
						updateDialog(currentFigureIndex);
					}
					break;
					case 'Escape':
					dialog.close();
					document.body.style.overflow = ''; // Allow scrolling again when dialog is closed.
					break;
			}
		});
	}


	// Wait for the DOM to load before running the following functions
	document.addEventListener("DOMContentLoaded", function() {
		updateAriaExpanded();
		handleTogglers();
		addScrollButton();
		headerShowHide();
		dialogLightBox();
	});
}());


/**
 * Clicky Menus v1.2.0
 */

( function() {
	'use strict';

	const ClickyMenus = function( menu ) {
		// DOM element(s)
		const container = menu.parentElement;
		let currentMenuItem,
			i,
			len;

		this.init = function() {
			menuSetup();
			document.addEventListener( 'click', closeIfClickOutsideMenu );
			// custom event to allow outside scripts to close submenus
			menu.addEventListener( 'clickyMenusClose', closeOpenSubmenu );
		};

		/*===================================================
		=            Menu Open / Close Functions            =
		===================================================*/
		function toggleOnMenuClick( e ) {
			const button = e.currentTarget;

			// close open menu if there is one
			if ( currentMenuItem && button !== currentMenuItem ) {
				toggleSubmenu( currentMenuItem );
			}

			toggleSubmenu( button );
		}

		function toggleSubmenu( button ) {
			const submenu = document.getElementById( button.getAttribute( 'aria-controls' ) );

			if ( 'true' === button.getAttribute( 'aria-expanded' ) ) {
				button.setAttribute( 'aria-expanded', false );
				submenu.setAttribute( 'aria-hidden', true );
				currentMenuItem = false;
			} else {
				button.setAttribute( 'aria-expanded', true );
				submenu.setAttribute( 'aria-hidden', false );
				preventOffScreenSubmenu( submenu );
				currentMenuItem = button;
			}
		}

		function preventOffScreenSubmenu( submenu ) {
			const 	screenWidth =	window.innerWidth ||
									document.documentElement.clientWidth ||
									document.body.clientWidth,
				parent = submenu.offsetParent,
				menuLeftEdge = parent.getBoundingClientRect().left,
				menuRightEdge = menuLeftEdge + submenu.offsetWidth;

			if ( menuRightEdge + 32 > screenWidth ) { // adding 32 so it's not too close
				submenu.classList.add( 'sub-menu--right' );
			}
		}

		function closeOnEscKey( e ) {
			if (	27 === e.keyCode ) {
				// we're in a submenu item
				if ( null !== e.target.closest( 'ul[aria-hidden="false"]' ) ) {
					currentMenuItem.focus();
					toggleSubmenu( currentMenuItem );

				// we're on a parent item
				} else if ( 'true' === e.target.getAttribute( 'aria-expanded' ) ) {
					toggleSubmenu( currentMenuItem );
				}
			}
		}

		function closeIfClickOutsideMenu( e ) {
			if ( currentMenuItem && ! e.target.closest( '#' + container.id ) ) {
				toggleSubmenu( currentMenuItem );
			}
		}

		function closeOpenSubmenu() {
			if( currentMenuItem ) {
				toggleSubmenu( currentMenuItem );
			}
		}

		/*===========================================================
		=            Modify Menu Markup & Bind Listeners            =
		=============================================================*/
		function menuSetup() {
			menu.classList.remove( 'no-js' );
			const submenuSelector = 'clickySubmenuSelector' in menu.dataset ? menu.dataset.clickySubmenuSelector : 'ul';

			menu.querySelectorAll( submenuSelector ).forEach( ( submenu ) => {
				const menuItem = submenu.parentElement;

				if ( 'undefined' !== typeof submenu ) {
					const button = convertLinkToButton( menuItem );

					setUpAria( submenu, button );

					// bind event listener to button
					button.addEventListener( 'click', toggleOnMenuClick );
					menu.addEventListener( 'keyup', closeOnEscKey );
				}
			} );
		}

		/**
		 * Why do this? See https://justmarkup.com/articles/2019-01-21-the-link-to-button-enhancement/
		 *
		 * @param {HTMLElement} menuItem An element representing a link to be converted to a button
		 */
		function convertLinkToButton( menuItem ) {
			const 	link = menuItem.getElementsByTagName( 'a' )[ 0 ],
				linkHTML = link.innerHTML,
				linkAtts = link.attributes,
				button = document.createElement( 'button' );

			if ( null !== link ) {
				// copy button attributes and content from link
				button.innerHTML = linkHTML.trim();
				for ( i = 0, len = linkAtts.length; i < len; i++ ) {
					const attr = linkAtts[ i ];
					if ( 'href' !== attr.name ) {
						button.setAttribute( attr.name, attr.value );
					}
				}

				menuItem.replaceChild( button, link );
			}

			return button;
		}

		function setUpAria( submenu, button ) {
			const submenuId = submenu.getAttribute( 'id' );

			let id;
			if ( null === submenuId ) {
				id = button.textContent.trim().replace( /\s+/g, '-' ).toLowerCase() + '-submenu';
			} else {
				id = submenuId + '-submenu';
			}

			// set button ARIA
			button.setAttribute( 'aria-controls', id );
			button.setAttribute( 'aria-expanded', false );

			// set submenu ARIA
			submenu.setAttribute( 'id', id );
			submenu.setAttribute( 'aria-hidden', true );
		}
	};

	/* Create a ClickMenus object and initiate menu for any menu with .clicky-menu class */
	document.addEventListener( 'DOMContentLoaded', function() {
		const menus = document.querySelectorAll( '.clicky-menu' );

		menus.forEach( ( menu ) => {
			const clickyMenu = new ClickyMenus( menu );
			clickyMenu.init();
		} );
	} );
}() );



