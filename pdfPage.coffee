app = angular.module 'pdfPage', []

app.directive 'pdfPage', ['$timeout', ($timeout) ->
	{
		require: '^pdfViewer',
		template: '<div class="pdf-canvas"></div><div class="text"></div><div class="annotation"></div>'
		link: (scope, element, attrs, ctrl) ->
			# TODO: do we need to destroy the watch or is it done automatically?
			#console.log 'in pdfPage link', scope.page.pageNum, 'sized', scope.page.sized, 'defaultPageSize', scope.defaultPageSize

			canvasElement = $(element).find('.pdf-canvas')

			updatePageSize = (size) ->
				element.height(Math.floor(size[0]))
				element.width(Math.floor(size[1]))
				#element.removeClass('pdf-canvas-new')
				##console.log 'updating Canvas Size to', '[', size[0], size[1], ']'
				scope.page.sized = true

			isVisible = (containerSize) ->
				elemTop = element.offset().top - containerSize[2]
				elemBottom = elemTop + element.innerHeight()
				visible = (elemTop < containerSize[1] and elemBottom > 0)
				scope.page.visible = visible
				scope.page.elemTop = elemTop
				scope.page.elemBottom = elemBottom
				#console.log 'checking visibility', scope.page.pageNum, elemTop, elemBottom, scrollWindow[0], scrollWindow[1], visible
				return visible

			renderPage = () ->
				#scope.page.rendered = true
				scope.document.renderPage canvasElement, scope.page.pageNum

			pausePage = () ->
				scope.document.pause canvasElement, scope.page.pageNum


			if (!scope.page.sized && scope.defaultPageSize)
				console.log('setting page size in directive', scope.defaultPageSize, scope.page.pageNum)
				updatePageSize scope.defaultPageSize

			if scope.page.current
					console.log 'we must scroll to this page', scope.page.pageNum,
						'at position', scope.page.position
					newpos = $(element).offset().top - $(element).parent().offset().top
					console.log('top of page scroll is', newpos)
					#newpos = newpos + scope.page.position * $(element).innerHeight() + 10 + 5
					console.log('inner height is', $(element).innerHeight())
					offset = scope.page.position * ($(element).innerHeight() + 10)
					console.log('addition offset =', offset, 'total', newpos+offset)
					scope.$parent.pleaseScrollTo = newpos + offset
					renderPage()


			scope.$watch 'defaultPageSize', (defaultPageSize) ->
				console.log 'in defaultPageSize watch', defaultPageSize, 'page', scope.page
				return unless defaultPageSize?
				#return if (scope.page.rendered or scope.page.sized)
				console.log('setting page size in watch', scope.defaultPageSize, 'with Scale', scope.pdfScale)
				updatePageSize defaultPageSize

			watchHandle = scope.$watch 'containerSize', (containerSize, oldVal) ->
				#console.log 'in scrollWindow watch', 'scope.scrollWindow', scope.$parent.scrollWindow, 'defaultPageSize', scope.$parent.defaultPageSize, 'scale', scope.$parent.pdfScale
				return unless containerSize?
				#console.log 'scrolling', scope.page.pageNum, 'page', scope.page, 'scrollWindow', scrollWindow, 'oldVal', oldVal
				return unless scope.page.sized
				oldVisible = scope.page.visible
				newVisible = scope.page.visible = isVisible containerSize
				if newVisible && !oldVisible
					renderPage()
				else if !newVisible && oldVisible
					pausePage()
				#watchHandle() # deregister this listener after the page is rendered
	}
]
