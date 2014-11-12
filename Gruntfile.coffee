fs = require "fs"

module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-watch'

	config =
		coffee:
			app_dir:
				expand: true,
				flatten: false,
				src: ['*.coffee'],
				ext: '.js'
		watch:
			files: ['*.coffee']
			tasks: ['coffee']

	grunt.initConfig config

	grunt.registerTask 'compile', 'Compile the script', ['coffee']
