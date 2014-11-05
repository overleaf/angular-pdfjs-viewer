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
		$scope.loaded = $q.all({
			pdfPageSize: $scope.document.getPdfPageSize()
			numPages: $scope.document.getNumPages()
			}).then (result) ->
				$scope.pdfPageSize = [
					result.pdfPageSize[0],
					result.pdfPageSize[1]
				]
				$scope.numPages = result.numPages

	@setScale = (scale, containerHeight, containerWidth) ->
		$scope.loaded.then () ->
			console.log 'in setScale', scale, containerHeight, containerWidth
			numScale = 1
			if scale == 'w'
				# TODO scrollbar width is 17, make this dynamic
				numScale = (containerWidth - 17) / ($scope.pdfPageSize[1])
				#console.log('new scale', numScale)
				$scope.document.setScale(numScale)
			else if scale == 'h'
				numScale = (containerHeight) / ($scope.pdfPageSize[0])
				#console.log('new scale', numScale)
				$scope.document.setScale(numScale)
			else
				numScale = scale
				$scope.document.setScale(scale)
			#console.log 'reseting pages array for', $scope.numPages
			#
			$scope.defaultCanvasSize = [
				numScale * $scope.pdfPageSize[0],
				numScale * $scope.pdfPageSize[1]
			]
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
				#console.log 'scroll detected', a,b
				scope.scrollWindow = [a, b]

			updateScrollWindow()

			element.on 'scroll', () ->
				scope.ScrollTop = element.scrollTop()
				updateScrollWindow()
				scope.$apply()

			scope.$watch 'pdfSrc', () ->
				ctrl.refresh()
				ctrl.setScale(scope.pdfScale, element.innerHeight(), element.innerWidth())

			scope.$watch 'pdfScale', (newVal, oldVal) ->
				return if newVal == oldVal # no need to set scale when initialising, done in pdfSrc
				ctrl.setScale(newVal, element.innerHeight(), element.innerWidth())
	}

app.directive 'pdfPage', () ->
	{
		require: '^pdfViewer',
		link: (scope, element, attrs, ctrl) ->
			# TODO: do we need to destroy the watch or is it done automatically?
			#console.log 'in pdfPage link', scope.page.pageNum, 'sized', scope.page.sized, 'defaultCanvasSize', scope.defaultCanvasSize
			updateCanvasSize = (size) ->
				canvas = element[0]
				[canvas.height, canvas.width] = [size[0], size[1]]
				#console.log 'updating Canvas Size to', scale, '*', '[', size[0], size[1], ']'
				scope.page.sized = true

			isVisible = (scrollWindow) ->
				elemTop = element.offset().top
				elemBottom = elemTop + element.height()
				visible = (elemTop < scrollWindow[1]) and (elemBottom > scrollWindow[0])
				#console.log 'checking visibility', scope.page.pageNum, elemTop, elemBottom, scrollWindow[0], scrollWindow[1], visible
				return visible

			renderPage = () ->
				scope.page.rendered = true
				scope.document.renderPage element[0], scope.page.pageNum

			if (!scope.page.sized && scope.defaultCanvasSize)
				#console.log('setting canvas size in directive', scope.defaultCanvasSize)
				updateCanvasSize scope.defaultCanvasSize

			scope.$watch 'defaultCanvasSize', (defaultCanvaSize) ->
				#console.log 'in CanvasSize watch', 'scope.scrollWindow', scope.$parent.scrollWindow, 'defaultCanvasSize', scope.$parent.defaultCanvasSize, 'scale', scope.$parent.pdfScale
				return unless defaultCanvasSize?
				return if (scope.page.rendered or scope.page.sized)
				#console.log('setting canvas size in watch', scope.defaultCanvasSize, 'with Scale', scope.pdfScale)
				updateCanvasSize defaultCanvasSize

			scope.$watch 'scrollWindow', (scrollWindow, oldVal) ->
				#console.log 'in scrollWindow watch', 'scope.scrollWindow', scope.$parent.scrollWindow, 'defaultCanvasSize', scope.$parent.defaultCanvasSize, 'scale', scope.$parent.pdfScale
				#console.log 'scrolling', scope.page.pageNum, 'page', scope.page, 'scrollWindow', scrollWindow, 'oldVal', oldVal
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

		getPdfPageSize: () ->
			@document.then (pdfDocument) =>
				pdfDocument.getPage(1).then (page) =>
					#console.log 'scale is', scale
					viewport = page.getViewport 1
					[viewport.height, viewport.width]

		getScale: () ->
			@scale

		setScale: (@scale) ->

		renderPage: (canvas, pagenum) ->
			scale = @scale
			@document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum).then (page) ->
					console.log 'rendering at scale', scale, 'pagenum', pagenum
					viewport = page.getViewport scale
					[canvas.height, canvas.width] = [viewport.height, viewport.width]
					page.render {
						canvasContext: canvas.getContext '2d'
						viewport: viewport
						}
	]
