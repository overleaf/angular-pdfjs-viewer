/*global PDFJS: false, $: false */

var url = '0703198.pdf'; // example file

PDFJS.disableAutoFetch = true;
PDFJS.verbosity = PDFJS.VERBOSITY_LEVELS.infos;

PDFJS.getDocument(url).then(function (pdfDocument) {
    var numPages = pdfDocument.numPages;
    var container = $('#viewerContainer');
    var scale = 0.5;

    // load the first page to get the size
    pdfDocument.getPage(1).then(function (page) {
	var viewport = page.getViewport(scale);
	return viewport;
    }).then(function (viewport) {
	// set up canvas elements for all pages
	// assume they are the same size
	var i;
	for (i = 1; i <= numPages; i++) {
	    $('<h3>' + i + '</h3>').appendTo(container);
	    $('<canvas>').appendTo(container)
		.addClass('page')
	    // put page number in data-pagenum attribute
		.attr('data-pagenum', i)
		.attr('height', viewport.height)
		.attr('width', viewport.width);
	}
    });

    var render_cache = []; // keep track of which page numbers have been rendered

    container.on('scroll', function () {
	var docViewTop = container.offset().top;
	var docViewBottom = docViewTop + container.height();

	container.children('canvas').map(function () {
	    var pagenum = +($(this).attr('data-pagenum')); // convert to integer
	    var elemTop =  $(this).offset().top;
	    var elemBottom = elemTop + $(this).height();
	    var visible = ((elemTop < docViewBottom ) && (elemBottom > docViewTop));
	    var canvas = $(this)[0];
	    if (visible) {
		if (render_cache[pagenum]) {
		    console.log("found visible page", pagenum, 'already rendered');
		    return;
		} else {
		    console.log("found visible page", pagenum, 'RENDERING');
		};
		renderPage(canvas, pagenum);
		render_cache[pagenum] = true;
	    };
	});
	console.log('scrolling', docViewTop, docViewBottom);
    });

    container.on('click', 'canvas', function () {
	var pagenum = $(this).attr('data-pagenum');
	console.log('clicked on' , $(this), pagenum);
	var canvas = $(this)[0];
	// load and render the page here
	renderPage(canvas, pagenum);
    });

    var renderPage = function (canvas, pagenum) {
	pdfDocument.getPage(pagenum).then(function (page) {
	    var viewport = page.getViewport(scale);
	    canvas.height = viewport.height;
	    canvas.width = viewport.width;
	    page.render({
		canvasContext: canvas.getContext('2d'),
		viewport: viewport
	    });
	});
    };
});
