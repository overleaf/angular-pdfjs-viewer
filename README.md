Incremental PDF rendering
=========================

Initial example in `example-pdfjs/`

    $ npm install
    $ npm test

Load up `http://localhost:3000/` and select the scroll or click
example pages -- the pdf in each one should be loaded and rendered
incrementally.

PDF.js loads the file in 64KB chunks, so if you click or scroll to
nearby pages they sometimes render immediately as the data is already
loaded.

This repository is no longer maintained and has now been archived.

Notes
-----

In chrome the byte loading can hit the error Issue 77085:
net::ERR_CACHE_OPERATION_NOT_SUPPORTED

https://code.google.com/p/chromium/issues/detail?id=77085

The solution is to send a STRONG Etag, not a weak one.  We may need
some server side configuration to ensure this, because we need to know
if the PDF has changed.
