demoApp = angular.module 'pdfDemo', ['pdfViewerApp']

window.demoApp = demoApp

demoApp.controller 'pdfDemoCtrl', ['$scope',  ($scope) ->
	$scope.pdfSrc = 'example-pdfjs/content/0703198.pdf'
	$scope.pdfSrc2 = 'example-pdfjs/content/0703198.pdf'
	$scope.pdfScale = 1
	$scope.pdfScale2 = 1
	]

app = angular.module 'pdfViewerApp', []

window.app = app

app.controller 'pdfViewerController', ['$scope', '$q', 'PDF', '$element', ($scope, $q, PDF, $element) ->
	@refresh = () ->
		return unless $scope.pdfSrc # skip empty pdfsrc
		$scope.document = new PDF($scope.pdfSrc, {scale: 1})

		$q.all({
			defaultSize: $scope.document.getDefaultSize()
			numPages: $scope.document.getNumPages()
			}).then (result) ->
				defaultSize = result.defaultSize
				$scope.defaultSize = [defaultSize[0], defaultSize[1]]
				$scope.pages = ({
					pageNum: i
				} for i in [1 .. result.numPages])
				$scope.numPages = result.numPages


	@setScale = (scale, containerHeight, containerWidth) ->
		console.log 'in setScale', scale
		if scale == 'w'
			# TODO scrollbar width is 17, make this dynamic
			newScale = (containerWidth - 17) / ($scope.defaultSize[1])
			console.log('new scale', newScale)
			$scope.document.setScale(newScale)
		else if scale == 'h'
			newScale = (containerHeight) / ($scope.defaultSize[0])
			console.log('new scale', newScale)
			$scope.document.setScale(newScale)
		else
			$scope.document.setScale(scale)
		console.log 'reseting pages array for', $scope.numPages
		$scope.pages = ({
					pageNum: i
				} for i in [1 .. $scope.numPages])

	# @zoomIn = () ->
	#		scale = $scope.document.getScale()
	#		$scope.document.setScale(scale * 1.2)
	]

app.directive 'pdfViewer', () ->
	{
		controller: 'pdfViewerController'
		scope: {
			pdfSrc: "@"
			pdfScale: '@'
		}
		template: "Src={{pdfSrc}} Scale={{pdfScale}} <canvas data-pdf-page ng-repeat='page in pages'></canvas>"
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

			scope.$watch 'pdfSrc', () ->
				ctrl.refresh()

			scope.$watch 'pdfScale', (val) ->
				ctrl.setScale(val, element.innerHeight(), element.innerWidth())
	}

app.directive 'pdfPage', () ->
	{
		require: '^pdfViewer',
		link: (scope, element, attrs, ctrl) ->
			# TODO: do we need to destroy the watch or is it done automatically?
			console.log 'in pdfPage link', scope.page.pageNum, 'sized', scope.page.sized, 'defaultSize', scope.defaultSize
			updateCanvasSize = (size, scale) ->
				canvas = element[0]
				[canvas.height, canvas.width] = [size[0]*scale, size[1]*scale]
				scope.page.sized = true

			isVisible = (scrollWindow) ->
				elemTop = element.offset().top
				elemBottom = elemTop + element.height()
				(elemTop < scrollWindow[1]) and (elemBottom > scrollWindow[0])

			renderPage = () ->
				scope.page.rendered = true
				scope.document.renderPage element[0], scope.page.pageNum

			if (!scope.page.sized && scope.defaultSize && scope.scale)
				console.log('setting canvas size', scope.defaultSize)
				updateCanvasSize scope.defaultSize, scope.scale

			scope.$watch 'defaultSize', (defaultSize) ->
				return unless defaultSize?
				return if (scope.page.rendered or scope.page.sized)
				updateCanvasSize defaultSize, scope.scale

			scope.$watch 'scrollWindow', (scrollWindow) ->
				return unless scope.page.sized
				return if scope.page.rendered
				return unless isVisible scrollWindow
				renderPage()
	}

app.factory 'PDF', ['$q', ($q) ->
	PDFJS.disableFetch = true
	class PDF
		constructor: (@url, @options) ->
			@scale = @options.scale || 1
			@document = $q.when(PDFJS.getDocument @url)

		getNumPages: () ->
			@document.then (pdfDocument) ->
				pdfDocument.numPages

		getDefaultSize: () ->
			scale = @scale
			@document.then (pdfDocument) =>
				pdfDocument.getPage(1).then (page) =>
					console.log 'scale is', scale
					viewport = page.getViewport scale
					[viewport.height, viewport.width]

		getScale: () ->
			@scale

		setScale: (@scale) ->

		renderPage: (canvas, pagenum) ->
			scale = @scale
			@document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum).then (page) ->
					viewport = page.getViewport scale
					[canvas.height, canvas.width] = [viewport.height, viewport.width]
					page.render {
						canvasContext: canvas.getContext '2d'
						viewport: viewport
						}
	]
