Incremental PDF rendering
=========================

Initial example in `example-pdfjs/`

    $ npm install
    $ npm test

Load up `http://localhost:3000/` and click on the pages -- each one
should be loaded and rendered incrementally.

PDF.js loads the file in 64KB chunks, so if you click on nearby pages
they sometimes render immediately as the data is already loaded.