/*global PDFJS: false, $: false, angular: false */

var app = angular.module('pdfViewer', []);

app.controller('Controller', ['$scope', function($scope) {
    var url = 'example-pdfjs/content/0703198.pdf'; // example file
    PDFJS.disableAutoFetch = true;
    PDFJS.verbosity = PDFJS.VERBOSITY_LEVELS.infos;
    $scope.pdfDocument = {};
    $scope.numPages = 0;
    PDFJS.getDocument(url).then(function (pdfDocument) {
	var numPages = pdfDocument.numPages;
	var scale = 0.5;
	var i;
	// create the list of pages with ng repeat
	$scope.pages = [];
	for (i = 1; i<= numPages; i++) {
	    $scope.pages[i-1] = i;
	};
	$scope.numPages = numPages;
	$scope.pdfDocument = pdfDocument;
	$scope.$apply();
	console.log("loaded", numPages);
	// load the first page to get the size
	pdfDocument.getPage(1).then(function (page) {
	    var viewport = page.getViewport(scale);
	    return viewport;
	});
    });
}]);

app.directive('myPdfviewer', function() {
    return {
	template: "<div data-my-pdf-page ng-repeat='page in pages'></div>",
	link: function (scope, element, attrs) {
	    element.on('scroll', function () {
		console.log('scrolling');
	    });
	}
    };
});

app.directive('myPdfPage', function() {
    return {
	template: "<canvas style='height: 300px; width: 300px; border: 1px solid black'></canvas>{{page}}",
	link: function (scope, element, attrs) {
	}
    };
});
