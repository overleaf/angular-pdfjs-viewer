app = angular.module 'pdfViewerApp', ['pdfPage', 'PDFRenderer', 'pdfHighlights']

window.app = app

app.controller 'pdfViewerController', ['$scope', '$q', 'PDFRenderer', '$element', 'pdfHighlights', ($scope, $q, PDFRenderer, $element, pdfHighlights) ->
	@load = () ->
		return unless $scope.pdfSrc # skip empty pdfsrc
		# TODO passing the scope is a hack, need to fix this
		$scope.document = new PDFRenderer($scope.pdfSrc, {
			scale: 1,
			scope: $scope
		})
		$scope.loaded = $q.all({
			pdfViewport: $scope.document.getPdfViewport 1, 1 # get size of first page as default @ scale 1
			numPages: $scope.document.getNumPages()
			destinations: $scope.document.getDestinations()
			}).then (result) ->
				$scope.pdfViewport = result.pdfViewport
				$scope.pdfPageSize = [
					result.pdfViewport.height,
					result.pdfViewport.width
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
			$scope.scale = $scope.numScale
			$scope.document.setScale($scope.numScale)
			$scope.defaultPageSize = [
				$scope.numScale * $scope.pdfPageSize[0],
				$scope.numScale * $scope.pdfPageSize[1]
			]

	@redraw = (position) ->
		console.log 'in redraw'
		console.log 'reseting pages array for', $scope.numPages, 'position is', position
		$scope.pages = ({
			pageNum: i
		} for i in [1 .. $scope.numPages])
		if position? && position.page?
			console.log 'setting current page', position.page
			pagenum = position.page
			$scope.pages[pagenum - 1].current = true
			$scope.pages[pagenum - 1].position = position

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

	@showRandomHighlights = () ->
		console.log 'show highlights'
		$scope.highlights = [
			{
				page: 3
				h: 100
				v: 100
				height: 30
				width: 200
			}
		]

	# we work with (pagenumber, % of height down page from top)
	# pdfListView works with (pagenumber, vertical position up page from bottom measured in pts)

	@getPdfPosition = () ->
		console.log 'in getPdfPosition'
		visiblePages = $scope.pages.filter (page) ->
			page.visible
		topPage = visiblePages[0]
		console.log 'top page is', topPage.pageNum, topPage.elemTop, topPage.elemBottom
		span = topPage.elemBottom - topPage.elemTop
		console.log 'elemTop', topPage.elemTop
		if topPage.elemTop > 0
			position = -topPage.elemTop
		else
			position = -topPage.elemTop / span
		console.log 'position', position, 'span', span
		console.log 'in PdflistView coordinates', topPage.pageNum
		return [topPage.pageNum, position]

	@getPdfPositionNEW = () ->
		console.log 'in getPdfPositionNEW'
		visiblePages = $scope.pages.filter (page) ->
			page.visible
		topPage = visiblePages[0]
		console.log 'top page is', topPage.pageNum, topPage.elemTop, topPage.elemBottom, topPage
		top = topPage.elemTop
		bottom = topPage.elemBottom
		viewportTop = 0
		viewportHeight = $element.height()
		topVisible = (top >= viewportTop && top < viewportTop + viewportHeight);
		someContentVisible = (top < viewportTop && bottom > viewportTop);
		console.log 'in PdfListView', top, topVisible, someContentVisible, viewportTop
		if topVisible
			canvasOffset = 0
		else if someContentVisible
			canvasOffset = viewportTop - top
		else
			canvasOffset = null
		console.log 'pdfListview position = ', canvasOffset
		# instead of using promise, check if size is known and revert to
		# default otherwise
		console.log 'looking up viewport', topPage.viewport, $scope.pdfViewport
		if topPage.viewport
			viewport = topPage.viewport
			pdfOffset = viewport.convertToPdfPoint(0, canvasOffset);
		else
			viewport = $scope.pdfViewport # second may need rescale
			pdfOffset = viewport.convertToPdfPoint(0, canvasOffset / $scope.numScale);
		console.log 'converted to offset = ', pdfOffset
		return { "page": topPage.pageNum,	"offset" : { "top" : pdfOffset[1], "left": 0	}	}

	@computeOffset = (element, position) ->
		pageTop = $(element).offset().top - $(element).parent().offset().top
		console.log('top of page scroll is', pageTop)
		console.log('inner height is', $(element).innerHeight())
		if position < 0
			offset = 10 + position
		else
			offset = 10 + position * $(element).innerHeight()
		console.log('addition offset =', offset, 'total', pageTop + offset)
		return Math.round(pageTop + offset)

	@setPdfPosition = (element, position) ->
		#console.log 'required pdf Position is', pdfPosition
		#page = pdfPosition.page
		#top = pdfPosition.top
		#pageElement = $scope.pages[page-1].element
		#$scope.pleaseScrollTo = $(pageElement).offset().top - $(pageElement).parent().offset().top + 10
		$scope.pleaseScrollTo = @computeOffset element, position


	@computeOffsetNEW = (page, position) ->
		element = page.element
		pageTop = $(element).offset().top - $(element).parent().offset().top
		console.log('top of page scroll is', pageTop)
		console.log('inner height is', $(element).innerHeight())
		offset = position.offset
		# convert offset to pixels
		viewport = page.viewport
		pageOffset = viewport.convertToViewportPoint(offset.left, offset.top)

		console.log('addition offset =', pageOffset, 'total', pageTop + pageOffset[1])
		return Math.round(pageTop + pageOffset[1] + 10) ## 10 is margin


	@setPdfPositionNEW = (page, position) ->
		console.log 'required pdf Position is', position
		$scope.pleaseScrollTo = @computeOffsetNEW page, position

]

app.directive 'pdfViewer', ['$q', '$timeout', ($q, $timeout) ->
	{
		controller: 'pdfViewerController'
		controllerAs: 'ctrl'
		scope: {
			"pdfSrc": "="
			"highlights": "="
			"position": "="
			"scale": "="
			"dblClickCallback": "="

			"pdfScale": '@'
		}
		template: """
		<div class='pdfviewer-controls'>
			<button ng-click='ctrl.fitWidth()'>Fit width</button>
			<button ng-click='ctrl.fitHeight()'>Fit height</button>
			<button ng-click='ctrl.zoomIn()'>Zoom In</button>
			<button ng-click='ctrl.zoomOut()'>Zoom Out</button>
			<button ng-click='ctrl.checkPosition()'>Check Position</button>
			<button ng-click='ctrl.showRandomHighlights()'>Check Highlights</button>
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
				origposition = angular.copy scope.position
				console.log 'origposition', origposition
				layoutReady.promise.then () ->
					[h, w] = [element.parent().innerHeight(), element.parent().width()]
					ctrl.setScale(scale, h, w).then () ->
						ctrl.redraw(origposition)

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

			element.parent().on 'scroll', () ->
				console.log 'scroll detected', scope.adjustingScroll
				updateContainer()
				scope.$apply()
				#console.log 'pdfposition', element.parent().scrollTop()
				if scope.adjustingScroll
					scope.adjustingScroll = false
					return
				#console.log 'not from auto scroll'
				scope.position = ctrl.getPdfPositionNEW()
				console.log 'position is', scope.position
				scope.$apply()

			scope.$watch 'pdfSrc', (newVal, oldVal) ->
				console.log 'loading pdf', newVal, oldVal
				ctrl.load()
				console.log 'XXX setting scale in pdfSrc watch'
				return if newVal == oldVal
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
				console.log 'forceCheck', newVal, oldVal
				scope.adjustingScroll = true  # temporarily disable scroll
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
				return unless newVal?
				scope.adjustingScroll = true  # temporarily disable scroll
																			# handler while we reposition
				$(element).parent().scrollTop(newVal)
				scope.pleaseScrollTo = undefined

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
							scope.pdf.currentPageNumber = p
							console.log 'r is', r, 'r[1]', r[1], 'r[1].name', r[1].name
							if r[1].name == 'XYZ'
								console.log 'XYZ:', r[2], r[3]
								e =$(scope.pages[p].element)
								console.log 'e is', e
								newpos = $(e).offset().top - $(e).parent().offset().top
								scope.adjustingScroll = true
								console.log 'scrolling to', newpos
								$(element).parent().scrollTop(newpos + scope.numScale * coords[1])

			scope.$watch "highlights", (areas) ->
					return if !areas?
					console.log 'areas are', areas
					highlights = for area in areas or []
						{
							page: area.page - 1
							highlight:
								left: area.h
								top: area.v
								height: area.height
								width: area.width
						}
					console.log 'highlights', highlights

					if highlights.length > 0
						first = highlights[0]
						ctrl.setPdfPosition({
							page: first.page
							offset:
								left: first.highlight.left
								top: first.highlight.top - 80
						}, true)

					# iterate over pages
					# highlightsElement = $(element).find('.highlights-layer')
					# highlightsLayer = new pdfHighlights({
					#		highlights: element.highlights[0]
					#		viewport: viewport
					# })
					#pdfListView.clearHighlights()
					#ctrl.setHighlights(highlights, true)

					#setTimeout () =>
					#	pdfListView.clearHighlights()
					#, 1000

	}
]
