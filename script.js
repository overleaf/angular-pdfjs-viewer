/*global PDFJS: false, $: false, angular: false */

var app = angular.module('pdfViewer', []);

app.controller('Controller', ['$scope', function($scope) {
    var url = 'example-pdfjs/content/0703198.pdf'; // example file
    PDFJS.disableAutoFetch = true;
    //PDFJS.verbosity = PDFJS.VERBOSITY_LEVELS.infos;
    $scope.pdfDocument = {};
    $scope.numPages = 0;
    $scope.scrollWindow = [];
    $scope.defaultViewPort = {};
    var scale = 0.5;

    var promise = PDFJS.getDocument(url);
    promise.then(function (pdfDocument) {
	var numPages = pdfDocument.numPages;
	var i;
	// create the list of pages with ng repeat
	$scope.pages = [];
	for (i = 1; i<= numPages; i++) {
	    $scope.pages[i-1] = { pageNum: i, state: 'empty', onscreen: false};
	};
	$scope.numPages = numPages;
	$scope.pdfDocument = pdfDocument;
	$scope.$apply();
	console.log("loaded", numPages);
	// load the first page to get the size
	pdfDocument.getPage(1).then(function (page) {
	    var viewport = page.getViewport(scale);
	    $scope.defaultViewport = viewport;
	    return viewport;
	});
    });

    // putting functions on the scope is not recommended,
    // use it now until I figure out the right way!
    $scope.renderPage = function (canvas, pagenum) {
	console.log('rendering page', pagenum);
	promise.then(function (pdfDocument) {
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
    };

    // $scope.$watch('scrollWindow', function (newVal, oldVal) {
    //	console.log('scrollTop was changed from', oldVal, 'to', newVal);
    // });

}]);

app.directive('myPdfviewer', function() {
    return {
	template: "<canvas data-my-pdf-page ng-repeat='page in pages'></canvas>",
	link: function (scope, element, attrs, ctrl) {
	    var updateScrollWindow = function () {
		var a = element.scrollTop(), b = a + element.height();
		scope.scrollWindow = [a, b];
	    };

	    updateScrollWindow();

	    element.on('scroll', function () {
		updateScrollWindow();
		scope.$apply();
		//console.log('scrolling', scope.scrollWindow);
	    });
	}
    };
});


app.directive('myPdfPage', function() {
    return {
	link: function (scope, element, attrs, ctrl) {
	    console.log('in link function for page', scope.page.pageNum);
	    //console.log('element', element, attrs);
	    scope.$watch('scrollWindow', function (scrollWindow) {
		// this calculation needs fixing up as per original incremental-scroll.js
		var elemTop =  scrollWindow[0] + element.offset().top;
		var elemBottom = elemTop + element.height();
		var visible = ((elemTop < scrollWindow[1] ) && (elemBottom > scrollWindow[0]));
		//console.log("page", scope.page.pageNum, elemTop, elemBottom, scrollWindow, visible);
		if (visible && !scope.page.rendered) {
		    scope.page.rendered = true;
		    scope.renderPage(element[0], scope.page.pageNum);
		};
	    });
	}
    };
});
