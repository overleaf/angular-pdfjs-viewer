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
		{ scaleMode: 'scale_mode_value', scale: 1 }
		{ scaleMode: 'scale_mode_value', scale: 0.5 }
		{ scaleMode: 'scale_mode_value', scale: 2 }
		{ scaleMode: 'scale_mode_fit_width' }
		{ scaleMode: 'scale_mode_fit_height' }
	]
	$scope.pdf = { url : $scope.pdfs[5], position: {}, scale: $scope.scales[3] }
	$scope.pdf2 = { url : $scope.pdfs[1], position: {}, scale: $scope.scales[4] }
	]
