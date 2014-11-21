app = angular.module 'pdfPage', []

app.directive 'pdfPage', ['$timeout', ($timeout) ->
	{
		require: '^pdfViewer',
		template: '''
		<div class="pdf-canvas"></div>
		<div class="plv-text-layer text-layer"></div>
		<div class="plv-annotations-layer annotations-layer"></div>
		<div class="plv-highlights-layer highlights-layer"></div>
		'''
		link: (scope, element, attrs, ctrl) ->
			canvasElement = $(element).find('.pdf-canvas')
			textElement = $(element).find('.text-layer')
			annotationsElement = $(element).find('.annotations-layer')
			highlightsElement = $(element).find('.highlights-layer')

			updatePageSize = (size) ->
				element.height(Math.floor(size[0]))
				element.width(Math.floor(size[1]))
				scope.page.sized = true

			isVisible = (containerSize) ->
				elemTop = element.offset().top - containerSize[2]
				elemBottom = elemTop + element.innerHeight()
				visible = (elemTop < containerSize[1] and elemBottom > 0)
				scope.page.visible = visible
				scope.page.elemTop = elemTop
				scope.page.elemBottom = elemBottom
				return visible

			renderPage = () ->
				scope.document.renderPage {
					canvas: canvasElement,
					text: textElement
					annotations: annotationsElement
					highlights: highlightsElement
				}, scope.page.pageNum

			pausePage = () ->
				scope.document.pause {
					canvas: canvasElement,
					text: textElement
				}, scope.page.pageNum

			# keep track of our page element, so we can access it in the
			# parent with scope.pages[i].element
			scope.page.element = element

			if (!scope.page.sized && scope.defaultPageSize)
				updatePageSize scope.defaultPageSize

			if scope.page.current
					console.log 'we must scroll to this page', scope.page.pageNum,
						'at position', scope.page.position
					# [a,b] = renderPage()
					# console.log 'AB', a, b
					# b.then (r) ->
					#		console.log '****************** HELLO in pdfPage', r
					# , (r) ->
					#		console.log '****************** HELLO FAIL in pdfPage', r
					# , (r) ->
					#		console.log '****************** HELLO update in pdfPage', r
					renderPage()
					scope.document.getPdfViewport(scope.page.pageNum).then (viewport) ->
						scope.page.viewport = viewport
						ctrl.setPdfPositionNEW(scope.page, scope.page.position)
					# console.log 'got promise for viewport in pdfPage', promise
					# promise.finally () ->
					#		console.log '*** in finally of renderpage'
					# promise.then () ->
					#		console.log '*** in resolve of renderPage', scope.page
					#		#ctrl.setPdfPositionNEW(scope.page, scope.page.position)
					# , () ->
					#		console.log '*** in fail of renderpage'
					# , () ->
					#		console.log '*** in update of renderpage'

			scope.$watch 'defaultPageSize', (defaultPageSize) ->
				return unless defaultPageSize?
				updatePageSize defaultPageSize

			watchHandle = scope.$watch 'containerSize', (containerSize, oldVal) ->
				return unless containerSize?
				return unless scope.page.sized
				oldVisible = scope.page.visible
				newVisible = isVisible containerSize
				scope.page.visible = newVisible
				if newVisible && !oldVisible
					renderPage()
					return
					#watchHandle() # deregister this listener after the page is rendered
				else if !newVisible && oldVisible
					pausePage()

	}
]
