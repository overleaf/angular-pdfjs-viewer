app = angular.module 'PDFRenderer', []

app.factory 'PDFRenderer', ['$q', ($q) ->
	PDFJS.disableAutoFetch = true
	class PDFRenderer
		constructor: (@url, @options) ->
			@scale = @options.scale || 1
			@document = $q.when(PDFJS.getDocument @url)
			@resetState()

		resetState: () ->
			console.log 'reseting renderer state'
			@paused = []
			@continuation = []
			@complete = []
			@pageLoader = []

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
			console.log 'in setScale of renderer', @scale
			@resetState()

		pause: (element, pagenum) ->
			return if @complete[pagenum]
			console.log 'paused page', pagenum
			@paused[pagenum] = true
			element.find('.fa-spin').removeClass('fa-spin')

		renderPage: (element, pagenum) ->
			scale = @scale
			self = this

			#console.log 'in render', 'paused=', @paused[pagenum], 'complete=',@complete[pagenum], 'continuation=',@continuation[pagenum], 'pageLoader=', @pageLoader[pagenum]

			if @complete[pagenum]
				console.log 'page', pagenum, 'is marked as completed'
				return

			if @paused[pagenum]
				console.log 'page', pagenum, 'was paused, now continuing'
				@paused[pagenum] = false
				element.find('.fa-spinner').addClass('fa-spin')

			if @continuation[pagenum]
				console.log 'page', pagenum, 'has a continuation, executing'
				@continuation[pagenum]()
				return

			if @pageLoader[pagenum]
				console.log 'page', pagenum, 'is already loading'
				return

			element.css({position: 'relative'})
			element.append('<div style="position: absolute; top: 50%; left:50%; font-size: 100px; transform: translateX(-50%) translateY(50%);"><i class="fa fa-5x fa-spinner fa-spin" style="color: #999"></i></div>')

			@pageLoader[pagenum] = @document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum)

			@pageLoader[pagenum].then (page) ->
				console.log 'rendering at scale', scale, 'pagenum', pagenum
				if (not scale?)
					console.log 'scale is undefined, returning'
					return

				canvas = $('<canvas class="pdf-canvas-new"></canvas>')

				viewport = page.getViewport (scale)

				devicePixelRatio = window.devicePixelRatio || 1

				ctx = canvas[0].getContext '2d'
				backingStoreRatio = ctx.webkitBackingStorePixelRatio ||
					ctx.mozBackingStorePixelRatio ||
					ctx.msBackingStorePixelRatio ||
					ctx.oBackingStorePixelRatio ||
					ctx.backingStorePixelRatio || 1
				pixelRatio = devicePixelRatio / backingStoreRatio

				scaledWidth = (Math.floor(viewport.width) * pixelRatio) | 0
				scaledHeight = (Math.floor(viewport.height) * pixelRatio) | 0

				newWidth = Math.floor(viewport.width);
				newHeight = Math.floor(viewport.height);

				#console.log 'devicePixelRatio is', devicePixelRatio
				#console.log 'viewport is', viewport
				#console.log 'devPixRatio size', devicePixelRatio*viewport.height, devicePixelRatio*viewport.width
				#console.log 'Ratios', devicePixelRatio, backingStoreRatio, pixelRatio

				canvas[0].height = scaledHeight
				canvas[0].width = scaledWidth

				#console.log Math.round(viewport.height) + 'px', Math.round(viewport.width) + 'px'

				canvas.height(newHeight + 'px')
				canvas.width(newWidth + 'px')

				if pixelRatio != 1
					ctx.scale(pixelRatio, pixelRatio)

				renderTask = page.render {
					canvasContext: ctx
					viewport: viewport
					continueCallback: (continueFn) ->
						console.log 'in continue callback'
						if self.paused[pagenum]
							console.log 'page', pagenum, 'is paused'
							self.continuation[pagenum] = continueFn
							return
						continueFn()
				}

				renderTask.promise.then () ->
					console.log 'page', pagenum, 'rendered completed!'
					self.complete[pagenum] = true
					delete self.continuation[pagenum]
					element.replaceWith(canvas)
					canvas.removeClass('pdf-canvas-new')

	]
