fs = require "fs"

module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	
	config =
		coffee:
			app_dir: 
				expand: true,
				flatten: false,
				src: ['*.coffee'],
				ext: '.js'

	grunt.initConfig config

	grunt.registerTask 'compile', 'Compile the script', ['coffee']

