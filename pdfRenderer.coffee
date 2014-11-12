app = angular.module 'PDFRenderer', []

app.factory 'PDFRenderer', ['$q', ($q) ->
	PDFJS.disableAutoFetch = true
	class PDFRenderer
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
			console.log 'in setScale of renderer', @scale

		renderPage: (element, pagenum) ->
			scale = @scale
			@document.then (pdfDocument) ->
				pdfDocument.getPage(pagenum).then (page) ->
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
					page.render {
						canvasContext: ctx
						viewport: viewport
					}

					element.replaceWith(canvas)
					canvas.removeClass('pdf-canvas-new')
	]
