demoApp = angular.module 'pdfDemo', ['pdfViewerApp']

window.demoApp = demoApp

demoApp.controller 'pdfDemoCtrl', ['$scope',  ($scope) ->
	$scope.pdfs = [
		'example-pdfjs/content/0703198.pdf'
		'example-pdfjs/content/1410.6514.pdf'
		'example-pdfjs/content/1410.6515.pdf'
		'example-pdfjs/content/0703198-mixed.pdf'
		'example-pdfjs/content/AMS55.pdf'
		'example-pdfjs/content/link-example.pdf'
		]
	$scope.scales = [
		1
		0.5
		2
		'w'
		'h'
	]
	$scope.pdfSrc = $scope.pdfs[5]
	$scope.pdfSrc2 = $scope.pdfs[1]
	$scope.pdfScale = 'w'
	$scope.pdfScale2 = 'h'
	$scope.pdfState = {}
	$scope.pdfState2 = {}
	$scope.pdf = { url : $scope.pdfs[5], position: {} }
	$scope.pdf2 = { url : $scope.pdfs[1], position: {} }
	]
