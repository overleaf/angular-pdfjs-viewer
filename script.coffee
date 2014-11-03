demoApp = angular.module 'pdfDemo', ['pdfViewerApp']

window.demoApp = demoApp

demoApp.controller 'pdfDemoCtrl', ['$scope',  ($scope) ->
	$scope.pdfSrc = 'example-pdfjs/content/0703198.pdf'
	$scope.pdfSrc2 = 'example-pdfjs/content/0703198.pdf'
	]

app = angular.module 'pdfViewerApp', []

window.app = app

app.controller 'pdfViewerController', ['$scope', '$q', 'PDF', ($scope, $q, PDF) ->
	refresh = () ->
		return unless $scope.pdfSrc # skip empty pdfsrc
		$scope.document = new PDF $scope.pdfSrc

		$q.all({
			defaultSize: $scope.document.getDefaultSize()
			numPages: $scope.document.getNumPages()
			}).then (result) ->
				defaultSize = result.defaultSize
				$scope.defaultSize = [defaultSize[0], defaultSize[1]]
				$scope.pages = ({
					pageNum: i
					state: 'empty'
					onscreen: false
				} for i in [1 .. result.numPages])
				$scope.numPages = result.numPages

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
				(elemTop < scrollWindow[1]) and (elemBottom > scrollWindow[0])

			renderPage = () ->
				scope.page.rendered = true
				scope.document.renderPage element[0], scope.page.pageNum

			scope.$watch 'defaultSize', (defaultSize) ->
				return unless defaultSize?
				return if (scope.page.rendered or scope.page.sized)
				updateCanvasSize defaultSize

			scope.$watch 'scrollWindow', (scrollWindow) ->
				return unless scope.page.sized
				return if scope.page.rendered
				return unless isVisible scrollWindow
				renderPage()
	}

app.factory 'PDF', ['$q', ($q) ->
	PDFJS.disableFetch = true
	scale = 0.5										# make this a settable parameter
	class PDF
		constructor: (@url) ->
			@document = $q.when(PDFJS.getDocument @url)

		getNumPages: () ->
			@document.then (pdfDocument) ->
				pdfDocument.numPages

		getDefaultSize: () ->
			@document.then (pdfDocument) ->
				pdfDocument.getPage(1).then (page) ->
					viewport = page.getViewport scale
					[viewport.height, viewport.width]

		renderPage: (canvas, pagenum) ->
			@document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum).then (page) ->
					viewport = page.getViewport scale
					[canvas.height, canvas.width] = [viewport.height, viewport.width]
					page.render {
						canvasContext: canvas.getContext '2d'
						viewport: viewport
						}
	]
