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
	    $('<canvas>').appendTo(container)
		.addClass('page')
	    // put page number in data-pagenum attribute
		.attr('data-pagenum', i)
		.attr('height', viewport.height)
		.attr('width', viewport.width);
	}
    });

    container.on('click', 'canvas', function () {
	var pagenum = $(this).attr('data-pagenum');
	console.log('clicked on' , $(this), pagenum);
	var canvas = $(this)[0];
	// load and render the page here
	pdfDocument.getPage(pagenum).then(function (page) {
	    var viewport = page.getViewport(scale);
	    canvas.height = viewport.height;
	    canvas.width = viewport.width;
	    page.render({
		canvasContext: canvas.getContext('2d'),
		viewport: viewport
	    });
	});
    });
});
