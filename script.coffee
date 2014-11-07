demoApp = angular.module 'pdfDemo', ['pdfViewerApp']

window.demoApp = demoApp

demoApp.controller 'pdfDemoCtrl', ['$scope',  ($scope) ->
	$scope.pdfs = [
		'example-pdfjs/content/0703198.pdf'
		'example-pdfjs/content/1410.6514.pdf'
		'example-pdfjs/content/1410.6515.pdf'
		'example-pdfjs/content/0703198-mixed.pdf'
		]
	$scope.scales = [
		1
		0.5
		2
		'w'
		'h'
	]
	$scope.pdfSrc = $scope.pdfs[1]
	$scope.pdfSrc2 = $scope.pdfs[1]
	$scope.pdfScale = 'h'
	$scope.pdfScale2 = 'w'
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
			console.log 'in setScale scale', scale, 'container h x w', containerHeight, containerWidth
			if scale == 'w'
				# TODO margin is 10px, make this dynamic
				$scope.numScale = (containerWidth - 20) / ($scope.pdfPageSize[1])
				console.log('new scale', $scope.numScale)
			else if scale == 'h'
				# TODO magic numbers for jquery ui layout
				$scope.numScale = (containerHeight + 2 - 12 - 20) / ($scope.pdfPageSize[0])
				console.log('new scale', $scope.numScale)
			else
				$scope.numScale = scale

	@updateNumScale = () ->
		console.log 'reseting pages array for', $scope.numPages
		$scope.document.setScale($scope.numScale)
		$scope.defaultCanvasSize = [
			$scope.numScale * $scope.pdfPageSize[0],
			$scope.numScale * $scope.pdfPageSize[1]
		]
		$scope.pages = ({
			pageNum: i
		} for i in [1 .. $scope.numPages])

	@zoomIn = () ->
		console.log 'zoom in'
		$scope.numScale = $scope.numScale * 1.2

	@zoomOut = () ->
		console.log 'zoom out'
		$scope.numScale = $scope.numScale / 1.2
]

app.directive 'pdfViewer', ['$q', ($q) ->
	{
		controller: 'pdfViewerController'
		controllerAs: 'ctrl'
		scope: {
			pdfSrc: "@"
			pdfScale: '@'
		}
		template: "<button ng-click='ctrl.zoomIn()'>Zoom In</button> <button ng-click='ctrl.zoomOut()'>Zoom Out</button> <canvas data-pdf-page ng-repeat='page in pages'></canvas>"
		link: (scope, element, attrs, ctrl) ->
			console.log 'in pdfViewer element is', element
			layoutReady = $q.defer();
			layoutReady.notify 'waiting for layout'
			layoutReady.promise.then () ->
				console.log 'layoutReady was resolved'

			updateScrollWindow = () ->
				a = element.parent().offset().top
				b = a + element.parent().height()
				console.log 'scrollWindow size computed as', a, b
				scope.scrollWindow = [a, b]

			#updateScrollWindow()

			element.parent().on 'scroll', () ->
				console.log 'scroll detected'
				scope.ScrollTop = element.scrollTop()
				updateScrollWindow()
				scope.$apply()

			scope.$watch 'pdfSrc', () ->
				console.log 'loading pdf'
				ctrl.refresh()
				console.log 'XXX setting scale in pdfSrc watch'
				layoutReady.promise.then () ->
					ctrl.setScale(scope.pdfScale, element.parent().innerHeight(), element.width())

			scope.$watch 'pdfScale', (newVal, oldVal) ->
				return if newVal == oldVal # no need to set scale when initialising, done in pdfSrc
				console.log 'XXX calling Setscale in pdfScale watch'
				layoutReady.promise.then () ->
					ctrl.setScale(newVal, element.parent().innerHeight(), element.width())

			scope.$on 'layout-resize', () ->
				console.log 'GOT LAYOUT-RESIZE EVENT'
				#updateScrollWindow()
				scope.parentSize = [
					element.parent().innerHeight(),
					element.parent().innerWidth()
				]

			scope.$watch('parentSize', (newVal, oldVal) ->
				console.log 'XXX in parentSize watch', newVal, oldVal
				if newVal == oldVal
					console.log 'returning because old and new are the same'
					return
				console.log 'XXX calling setScale in parentSize watcher'
				ctrl.setScale(scope.pdfScale, element.parent().innerHeight(), element.width())
			, true)

			scope.$on 'layout-ready', () ->
				console.log 'GOT LAYOUT READY EVENT'
				console.log 'calling refresh'
				ctrl.refresh()
				console.log 'XXX calling setScale in layout-ready event'
				updateScrollWindow()
				layoutReady.resolve 'hello'
				scope.parentSize = [
					element.parent().innerHeight(),
					element.parent().innerWidth()
				]
				scope.$apply()

			scope.$watch 'numScale', (newVal, oldVal) ->
				return if newVal == oldVal
				console.log 'got change in numscale watcher', newVal, oldVal
				ctrl.updateNumScale()
	}
]

app.directive 'pdfPage', () ->
	{
		require: '^pdfViewer',
		link: (scope, element, attrs, ctrl) ->
			# TODO: do we need to destroy the watch or is it done automatically?
			#console.log 'in pdfPage link', scope.page.pageNum, 'sized', scope.page.sized, 'defaultCanvasSize', scope.defaultCanvasSize
			updateCanvasSize = (size) ->
				canvas = element[0]
				dpr = window.devicePixelRatio
				[canvas.height, canvas.width] = [Math.floor(dpr*size[0]), Math.floor(dpr*size[1])]
				element.height(Math.floor(size[0]))
				element.width(Math.floor(size[1]))
				##console.log 'updating Canvas Size to', '[', size[0], size[1], ']'
				scope.page.sized = true

			isVisible = (scrollWindow) ->
				elemTop = element.offset().top
				elemBottom = elemTop + element.height()
				visible = (elemTop < scrollWindow[1]) and (elemBottom > scrollWindow[0])
				#console.log 'checking visibility', scope.page.pageNum, elemTop, elemBottom, scrollWindow[0], scrollWindow[1], visible
				return visible

			renderPage = () ->
				scope.page.rendered = true
				scope.document.renderPage element, scope.page.pageNum

			if (!scope.page.sized && scope.defaultCanvasSize)
				#console.log('setting canvas size in directive', scope.defaultCanvasSize)
				updateCanvasSize scope.defaultCanvasSize

			scope.$watch 'defaultCanvasSize', (defaultCanvaSize) ->
				#console.log 'in CanvasSize watch', 'scope.scrollWindow', scope.$parent.scrollWindow, 'defaultCanvasSize', scope.$parent.defaultCanvasSize, 'scale', scope.$parent.pdfScale
				return unless defaultCanvasSize?
				return if (scope.page.rendered or scope.page.sized)
				#console.log('setting canvas size in watch', scope.defaultCanvasSize, 'with Scale', scope.pdfScale)
				updateCanvasSize defaultCanvasSize

			watchHandle = scope.$watch 'scrollWindow', (scrollWindow, oldVal) ->
				#console.log 'in scrollWindow watch', 'scope.scrollWindow', scope.$parent.scrollWindow, 'defaultCanvasSize', scope.$parent.defaultCanvasSize, 'scale', scope.$parent.pdfScale
				return unless scrollWindow?

				#console.log 'scrolling', scope.page.pageNum, 'page', scope.page, 'scrollWindow', scrollWindow, 'oldVal', oldVal
				return unless scope.page.sized
				return if scope.page.rendered
				return unless isVisible scrollWindow
				renderPage()
				watchHandle() # deregister this listener after the page is rendered
	}

app.factory 'PDF', ['$q', ($q) ->
	PDFJS.disableAutoFetch = true
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
					dpr = window.devicePixelRatio
					viewport = page.getViewport dpr*scale
					console.log 'devPixRatio size', devicePixelRatio*viewport.height, devicePixelRatio*viewport.width
					[canvas[0].height, canvas[0].width] = [viewport.height, viewport.width]
					console.log Math.round(viewport.height) + 'px', Math.round(viewport.width) + 'px'
					canvas.height(Math.floor(viewport.height/dpr) + 'px')
					canvas.width(Math.floor(viewport.width/dpr) + 'px')
					context = canvas[0].getContext '2d'
					backingStoreRatio = context.webkitBackingStorePixelRatio ||
						context.mozBackingStorePixelRatio ||
						context.msBackingStorePixelRatio ||
						context.oBackingStorePixelRatio ||
						context.backingStorePixelRatio || 1
					console.log 'backingStoreRatio', backingStoreRatio
					page.render {
						canvasContext: context
						viewport: viewport
						}
	]
