app = angular.module 'pdfViewerApp', ['pdfPage', 'PDFRenderer']

window.app = app

app.controller 'pdfViewerController', ['$scope', '$q', 'PDFRenderer', '$element', ($scope, $q, PDFRenderer, $element) ->
	@load = () ->
		return unless $scope.pdfSrc # skip empty pdfsrc
		# TODO passing the scope is a hack, need to fix this
		$scope.document = new PDFRenderer($scope.pdfSrc, {scale: 1, scope: $scope})
		$scope.loaded = $q.all({
			pdfPageSize: $scope.document.getPdfPageSize()
			numPages: $scope.document.getNumPages()
			destinations: $scope.document.getDestinations()
			}).then (result) ->
				$scope.pdfPageSize = [
					result.pdfPageSize[0],
					result.pdfPageSize[1]
				]
				$scope.destinations = result.destinations
				console.log 'resolved q.all, page size is', result
				$scope.numPages = result.numPages

	@setScale = (scale, containerHeight, containerWidth) ->
		$scope.loaded.then () ->
			console.log 'in setScale scale', scale, 'container h x w', containerHeight, containerWidth
			if scale == 'w'
				# TODO margin is 10px, make this dynamic
				$scope.numScale = (containerWidth - 15) / ($scope.pdfPageSize[1])
				console.log('new scale from width', $scope.numScale)
			else if scale == 'h'
				# TODO magic numbers for jquery ui layout
				$scope.numScale = (containerHeight) / ($scope.pdfPageSize[0])
				console.log('new scale from width', $scope.numScale)
			else
				$scope.numScale = scale
			console.log 'in setScale, numscale is', $scope.numScale
			$scope.document.setScale($scope.numScale)
			$scope.defaultPageSize = [
				$scope.numScale * $scope.pdfPageSize[0],
				$scope.numScale * $scope.pdfPageSize[1]
			]

	@redraw = (pagenum, pagepos) ->
		console.log 'in redraw'
		console.log 'reseting pages array for', $scope.numPages, 'pagenum is', pagenum
		$scope.pages = ({
			pageNum: i
		} for i in [1 .. $scope.numPages])
		if pagenum >= 0
			console.log 'setting current page', pagenum
			$scope.pages[pagenum - 1].current = true
			$scope.pages[pagenum - 1].position = pagepos

	@zoomIn = () ->
		console.log 'zoom in'
		$scope.forceScale = $scope.numScale * 1.2

	@zoomOut = () ->
		console.log 'zoom out'
		$scope.forceScale = $scope.numScale / 1.2

	@fitWidth = () ->
		console.log 'fit width'
		$scope.forceScale = 'w'

	@fitHeight = () ->
		console.log 'fit height'
		$scope.forceScale = 'h'

	@checkPosition = () ->
		console.log 'check position'
		$scope.forceCheck = ($scope.forceCheck || 0) + 1


]

app.directive 'pdfViewer', ['$q', '$timeout', ($q, $timeout) ->
	{
		controller: 'pdfViewerController'
		controllerAs: 'ctrl'
		scope: {
			pdfSrc: "@"
			pdfScale: '@'
			pdfState: '='
		}
		template: """
		<div class='pdfviewer-controls'>
			<button ng-click='ctrl.fitWidth()'>Fit width</button>
			<button ng-click='ctrl.fitHeight()'>Fit height</button>
			<button ng-click='ctrl.zoomIn()'>Zoom In</button>
			<button ng-click='ctrl.zoomOut()'>Zoom Out</button>
			<button ng-click='ctrl.checkPosition()'>Check Position</button>
		</div>
		<div data-pdf-page class='pdf-page-container plv-page-view page-view' ng-repeat='page in pages'></div>
		"""
		link: (scope, element, attrs, ctrl) ->
			console.log 'in pdfViewer element is', element
			console.log 'attrs', attrs
			layoutReady = $q.defer()
			layoutReady.notify 'waiting for layout'
			layoutReady.promise.then () ->
				console.log 'layoutReady was resolved'

			# TODO can we combine this with scope.parentSize, need to finalize boxes
			updateContainer = () ->
				scope.containerSize = [
					element.parent().innerWidth()
					element.parent().innerHeight()
					element.parent().offset().top
			]

			doRescale = (scale) ->
				console.log 'doRescale', scale
				origpagenum = if scope.pdfState.currentPageNumber? then +scope.pdfState.currentPageNumber else 1
				origpagepos = if scope.pdfState.currentPageNumber? then +scope.pdfState.currentPagePosition else -10
				console.log 'origpagenum', origpagenum, 'origpagepos', origpagepos
				layoutReady.promise.then () ->
					[h, w] = [element.parent().innerHeight(), element.parent().width()]
					ctrl.setScale(scale, h, w).then () ->
						ctrl.redraw(origpagenum, origpagepos)

			scope.$on 'layout-ready', () ->
				console.log 'GOT LAYOUT READY EVENT'
				console.log 'calling refresh'
				ctrl.load()
				updateContainer()
				layoutReady.resolve 'hello'
				scope.parentSize = [
					element.parent().innerHeight(),
					element.parent().innerWidth()
				]
				scope.$apply()

			scope.$on 'layout-resize', () ->
				console.log 'GOT LAYOUT-RESIZE EVENT'
				scope.parentSize = [
					element.parent().innerHeight(),
					element.parent().innerWidth()
				]
				scope.$apply()

			#scope.pdfState.currentPageNumber = 0
			#scope.pdfState.currentPagePosition = 0

			element.parent().on 'scroll', () ->
				console.log 'scroll detected', scope.adjustingScroll
				updateContainer()
				scope.$apply()
				#console.log 'pdfposition', element.parent().scrollTop()
				if scope.adjustingScroll
					scope.adjustingScroll = false
					return
				#console.log 'not from auto scroll'
				visiblePages = scope.pages.filter (page) ->
					#console.log 'page is', page, page.visible
					page.visible
				topPage = visiblePages[0]
				#console.log 'top page is', topPage.pageNum, topPage.elemTop, topPage.elemBottom
				# if pagenum > 1 then need to offset by half margin
				span = topPage.elemBottom - topPage.elemTop
				console.log 'elemTop', topPage.elemTop
				if topPage.elemTop > 0
					position = -topPage.elemTop
				else
					position = -topPage.elemTop / span
				console.log 'position', position, 'span', span
				scope.pdfState.currentPageNumber = topPage.pageNum
				scope.pdfState.currentPagePosition = position
				scope.$apply()

			scope.$watch 'pdfSrc', () ->
				console.log 'loading pdf'
				ctrl.load()
				console.log 'XXX setting scale in pdfSrc watch'
				doRescale scope.pdfScale

			scope.$watch 'pdfScale', (newVal, oldVal) ->
				return if newVal == oldVal # no need to set scale when initialising, done in pdfSrc
				console.log 'XXX calling Setscale in pdfScale watch'
				doRescale newVal

			scope.$watch 'forceScale', (newVal, oldVal) ->
				console.log 'got change in numscale watcher', newVal, oldVal
				return unless newVal?
				doRescale newVal

			scope.$watch 'forceCheck', (newVal, oldVal) ->
				doRescale scope.pdfScale

			scope.$watch('parentSize', (newVal, oldVal) ->
				console.log 'XXX in parentSize watch', newVal, oldVal
				if newVal == oldVal
					console.log 'returning because old and new are the same'
					return
				return unless oldVal?
				console.log 'XXX calling setScale in parentSize watcher'
				doRescale scope.pdfScale
			, true)

			scope.$watch 'elementWidth', (newVal, oldVal) ->
				console.log '*** watch INTERVAL element width is', newVal, oldVal

			scope.$watch 'pleaseScrollTo', (newVal, oldVal) ->
				console.log 'got request to ScrollTo', newVal, 'oldVal', oldVal
				scope.adjustingScroll = true  # temporarily disable scroll
																			# handler while we reposition
				$(element).parent().scrollTop(newVal)

			scope.$watch 'navigateTo', (newVal, oldVal) ->
				return unless newVal?
				console.log 'got request to navigate to', newVal, 'oldVal', oldVal
				scope.navigateTo = undefined
				console.log 'navigate to', newVal
				console.log 'look up page num'
				scope.loaded.then () ->
					console.log 'destinations are', scope.destinations
					r = scope.destinations[newVal.dest]
					console.log 'need to go to', r
					console.log 'page ref is', r[0]
					scope.document.getPageIndex(r[0]).then (p) ->
						console.log 'page num is', p
						scope.document.getPdfViewport(p).then (viewport) ->
							console.log 'got viewport', viewport
							coords = viewport.convertToViewportPoint(r[2],r[3]);
							console.log	'viewport position', coords
							scope.pdfState.currentPageNumber = p
							console.log 'r is', r, 'r[1]', r[1], 'r[1].name', r[1].name
							if r[1].name == 'XYZ'
								console.log 'XYZ:', r[2], r[3]
								e= $(element).find('.pdf-page-container')[p]
								console.log 'e is', e
								newpos = $(e).offset().top - $(e).parent().offset().top
								scope.adjustingScroll = true
								console.log 'scrolling to', newpos
								$(element).parent().scrollTop(newpos + scope.numScale * coords[1])

	}
]
