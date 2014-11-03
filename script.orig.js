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
    
    var refresh = function () {
	if (!$scope.pdfSrc) { console.log('empty pdfSrc'); return; }
	$scope.document = new PDF($scope.pdfSrc);

	// simplify/combine these promises can we get them as some
	// kind of dependency, possibly need to use angular $q
	// somewhere
	
	$scope.document.getNumPages().then(function (numPages) {
	    var i;
	    $scope.pages = [];
	    for (i = 1; i<= numPages; i++) {
		$scope.pages[i-1] = { pageNum: i, state: 'empty', onscreen: false};
	    };
	    $scope.numPages = numPages;
	    console.log("loaded", numPages);
	});

	$scope.document.getDefaultSize().then(function (defaultSize) {
	    $scope.defaultSize = [defaultSize[0], defaultSize[1]];
	    console.log('got viewport', $scope.defaultSize);
	    $scope.$apply(); // this should not really be here
			     // (e.g. numPages could resolve after
			     // getDefaultSize
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
		scope.document.renderPage(element[0], scope.page.pageNum);
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

app.factory('PDF', function () {
    PDFJS.disableAutoFetch = true;
    //PDFJS.verbosity = PDFJS.VERBOSITY_LEVELS.infos;

    var scale = 0.5; // make this a settable parameter

    var PDF = function (url) {
	this.url = url;
	this.document = PDFJS.getDocument(url);
    };

    PDF.prototype.getNumPages = function() {
	return this.document.then(function (pdfDocument) {
	    return pdfDocument.numPages;
	});
    };

    PDF.prototype.getDefaultSize = function () {
	return this.document.then(function (pdfDocument) {
	    return pdfDocument.getPage(1).then(function (page) {
		var viewport = page.getViewport(scale);
		return [viewport.height, viewport.width];
	    });
	});
    };

    PDF.prototype.renderPage = function (canvas, pagenum) {
	console.log('rendering page', pagenum);
	this.document.then(function (pdfDocument) {
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

    return PDF;
});
