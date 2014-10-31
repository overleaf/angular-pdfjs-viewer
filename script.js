/*global PDFJS: false, $: false, angular: false */


var demoApp = angular.module('pdfDemo', ['pdfViewerApp']);

demoApp.controller('pdfDemoCtrl', ['$scope', function($scope) {
    $scope.pdfSrc = 'example-pdfjs/content/0703198.pdf';
    $scope.pdfSrc2 = 'example-pdfjs/content/0703198.pdf';
}]);

var app = angular.module('pdfViewerApp', []);

app.controller('pdfViewerController', ['$scope', 'PDF', function($scope, PDF) {
    console.log('controller has been called');
    $scope.numPages = 0;
    $scope.scrollWindow = []; // [ offset top, offset bottom]
    $scope.defaultSize = [];

    var scale = 0.5;
    this.render = PDF.renderPage;

    var refresh = function () {
	if (!$scope.pdfSrc) { console.log('empty pdfSrc'); return; }
	var document = PDF.getDocument($scope.pdfSrc);

	document.then(function (pdfDocument) {
	    var numPages = pdfDocument.numPages;
	    var i;
	    // create the list of pages with ng repeat
	    $scope.pages = [];
	    for (i = 1; i<= numPages; i++) {
		$scope.pages[i-1] = { pageNum: i, state: 'empty', onscreen: false};
	    };
	    $scope.numPages = numPages;
	    //$scope.$apply();
	    console.log("loaded", numPages);
	});

	document.then(function (pdfDocument) {
	    pdfDocument.getPage(1).then(function (page) {
		var viewport = page.getViewport(scale);
		$scope.defaultSize = [viewport.height, viewport.width];
		console.log('got viewport', $scope.defaultSize);
		$scope.$apply();
		return viewport;
	    });
	});
    };
    
    $scope.$watch('pdfSrc', function (pdfSrc) {
	refresh();
    });
}]);

app.directive('pdfViewer', function() {
    return {
	controller: 'pdfViewerController',
	scope: { pdfSrc: "@" },
	template: "<canvas data-pdf-page ng-repeat='page in pages'></canvas>",
	link: function (scope, element, attrs, ctrl) {
	    var updateScrollWindow = function () {
		var a = element.offset().top, b = a + element.height();
		scope.scrollWindow = [a, b];
	    };

	    updateScrollWindow();

	    element.on('scroll', function () {
		scope.scrollTop = element.scrollTop();
		updateScrollWindow();
		scope.$apply();
	    });
	}
    };
});


app.directive('pdfPage', function() {
    return {
	require: '^pdfViewer',
	link: function (scope, element, attrs, ctrl) {
	    //console.log('in link function for page', scope.page.pageNum);
	    // TODO: do we need to destroy the watch or is it done automatically?

	    var updateCanvasSize = function (size) {
		var canvas = element[0];
		canvas.height = size[0];
		canvas.width = size[1];
		scope.page.sized = true;
	    };

	    var isVisible = function (scrollWindow) {
		var elemTop =  element.offset().top;
		var elemBottom = elemTop + element.height();
		return ((elemTop < scrollWindow[1] ) && (elemBottom > scrollWindow[0]));
	    };

	    var renderPage = function () {
		scope.page.rendered = true;
		ctrl.render(element[0], scope.page.pageNum);
	    };

	    if (!scope.page.sized ) {
		updateCanvasSize(scope.defaultSize);
	    };

	    scope.$watch('defaultSize', function (defaultSize) {
		if (scope.page.rendered || scope.page.sized) {
		    return;
		};
		updateCanvasSize(defaultSize);
	    });

	    scope.$watch('scrollWindow', function (scrollWindow) {
		if (!scope.page.rendered && isVisible(scrollWindow)) {
		    renderPage();
		};
	    });
	}
    };
});

app.service('PDF', function () {
    PDFJS.disableAutoFetch = true;	
    //PDFJS.verbosity = PDFJS.VERBOSITY_LEVELS.infos;

    var document;
    
    this.getDocument = function (url) {
	document = PDFJS.getDocument(url);
	return document;
    };

    // this.getNumPages = function () {
    // 	return PDFDocument.then(

    // this.defaultSize = function () {
    // };
    
    this.renderPage = function (canvas, pagenum) {
	console.log('rendering page', pagenum);
	document.then(function (pdfDocument) {
	    pdfDocument.getPage(pagenum).then(function (page) {
		var viewport = page.getViewport(0.5);
		canvas.height = viewport.height;
		canvas.width = viewport.width;
		page.render({
		    canvasContext: canvas.getContext('2d'),
		    viewport: viewport
		});
	    });
	});
    };
});

