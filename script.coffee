demoApp = angular.module 'pdfDemo', ['pdfViewerApp']

window.demoApp = demoApp

demoApp.controller 'pdfDemoCtrl', ['$scope',  ($scope) ->
	$scope.pdfSrc = 'example-pdfjs/content/0703198.pdf'
	$scope.pdfSrc2 = 'example-pdfjs/content/0703198.pdf'
	]
	
app = angular.module 'pdfViewerApp', []

window.app = app

app.controller 'pdfViewerController', ['$scope', 'PDF', ($scope, PDF) ->
	console.log 'controller has been called'
	$scope.numPages = 0
	$scope.scrollWindow = []		# [ offset top, offset bottom]
	$scope.defaultSize = []

	refresh = () ->
		return if !$scope.pdfSrc # empty pdfsrc
		$scope.document = new PDF $scope.pdfSrc
		# simplify/combine these promises can we get them as some
		# kind of dependency, possibly need to use angular $q
		# somewhere
		$scope.document.getNumPages().then (numPages) ->
			$scope.pages = ({
				pageNum: i
				state: 'empty'
				onscreen: false
			} for i in [1 .. numPages])
			$scope.numPages = numPages
			console.log("loaded", numPages)

		$scope.document.getDefaultSize().then (defaultSize) ->
			$scope.defaultSize = [defaultSize[0], defaultSize[1]]
			console.log 'got viewport', $scope.defaultSize
			$scope.$apply() # this should not really be here (e.g. numPages
			# could resolve after getDefaultSize)

	$scope.$watch 'pdfSrc', () ->
		refresh()
	]

app.directive 'pdfViewer', () ->
	{
		controller: 'pdfViewerController'
		scope: { pdfSrc: "@" }
		template: "<canvas data-pdf-page ng-repeat='page in pages'></canvas>"
		link: (scope, element, attrs, ctrl) ->
			updateScrollWindow = () ->
				a = element.offset().top
				b = a + element.height()
				scope.scrollWindow = [a, b]
			updateScrollWindow()
			element.on 'scroll', () ->
				scope.ScrollTop = element.scrollTop()
				updateScrollWindow()
				scope.$apply()
	}

app.directive 'pdfPage', () ->
	{
		require: '^pdfViewer',
		link: (scope, element, attrs, ctrl) ->
			# TODO: do we need to destroy the watch or is it done automatically?
			updateCanvasSize = (size) ->
				canvas = element[0]
				[canvas.height, canvas.width] = [size[0], size[1]]
				scope.page.sized = true

			isVisible = (scrollWindow) ->
				elemTop = element.offset().top
				elemBottom = elemTop + element.height()
				(elemTop < scrollWindow[1]) && (elemBottom > scrollWindow[0])

			renderPage = () ->
				scope.page.rendered = true
				scope.document.renderPage element[0], scope.page.pageNum

			if (!scope.page.sized)
				updateCanvasSize scope.defaultSize

			scope.$watch 'defaultSize', (defaultSize) ->
				return if (scope.page.rendered || scope.page.sized)
				updateCanvasSize defaultSize

			scope.$watch 'scrollWindow', (scrollWindow) ->
				console.log 'in scroll handler', scrollWindow, scope.page.rendered
				return if scope.page.rendered
				return unless isVisible scrollWindow
				renderPage()
	}

app.factory 'PDF', () ->
	PDFJS.disableFetch = true
	scale = 0.5										# make this a settable parameter
	class PDF
		constructor: (@url) ->
			@document = PDFJS.getDocument @url

		getNumPages: () ->
			@document.then (pdfDocument) ->
				pdfDocument.numPages

		getDefaultSize: () ->
			@document.then (pdfDocument) ->
				pdfDocument.getPage(1).then (page) ->
					viewport = page.getViewport scale
					[viewport.height, viewport.width]

		renderPage: (canvas, pagenum) ->
			console.log 'rendering page', pagenum
			@document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum).then (page) ->
					console.log 'page is', page
					viewport = page.getViewport scale
					console.log 'viewport is', viewport
					[canvas.height, canvas.width] = [viewport.height, viewport.width]
					page.render {
						canvasContext: canvas.getContext '2d'
						viewport: viewport
						}
