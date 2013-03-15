"use strict"

module.exports = (grunt) ->
  # Common options
  options =
    buildPath:  'lib'
    coffeePath: 'src'
    testPath:   'test'

  # Project configuration
  grunt.initConfig
    pkg: '<json:package.json>'

    coffeelint:
      main:
        files:
          src: ["#{options.coffeePath}/**/*.coffee", './*.coffee']
        options:
          max_line_length:
            level: "warn"

    coffee:
      main:
        expand:  yes
        cwd:     options.coffeePath
        src:     '**/*.coffee'
        dest:    options.buildPath
        ext: '.js'
      index:
        files:
          'index.js': 'index.coffee'
      tests:
        expand:  yes
        src: options.testPath + '/**/*.test.coffee'
        ext: '.test.js'
      funcTests:
        expand:  yes
        src: options.testPath + '/**/*.func.coffee'
        ext: '.func.js'

    mochaTest:
      files: ["#{options.testPath}/**/*.test.js"]
    mochaTestConfig:
      options:
        reporter: 'spec'

    watch:
      gruntfile:
        files: 'Gruntfile.*'
        tasks: ['compile', 'test']
      sources:
        files: [options.coffeePath + '/**/*.coffee', 'index.coffee']
        tasks: ['compile:main', 'compile:index', 'test']
      tests:
        files: [options.testPath + '**/*.test.coffee']
        tasks: ['compile:tests', 'test']
      funcTests:
        files: [options.testPath + '**/*.func.coffee']
        tasks: ['compile:funcTests', 'bgShell:run']
      testStuff:
        files: [options.testPath + 'responses/*']
        tasks: ['test']

    clean:
      build: [
        "doc"
        "lib"
        "test/**/*.test.js"
        "index.js"
      ]
      tests: "test/**/*.test.js"
      funcTests: "test/**/*.func.js"

    bgShell:
      run:
        cmd: 'node index.js'
        stdout: true
        stderr: true
        bg: false
        fail: false
        done: (err, stdout, stderr) ->
      codo:
        cmd: 'node_modules/.bin/codo'
        stdout: yes
        stderr: yes
        bg: no
        fail: no
        done: (err, stdout, stderr) ->

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-bg-shell'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-notify'

  # Documentation task.
  grunt.registerTask 'codo', ['bgShell:codo']

  # Test task.
  grunt.registerTask 'test', ['mochaTest']

  # Build clean task
  grunt.registerTask 'cleanup', ['clean:tests', 'clean:funcTests']

  # Compile task.
  grunt.registerTask 'compile', ['coffeelint', 'coffee']

  # Default task.
  grunt.registerTask 'default', ['clean', 'compile', 'test', 'cleanup', 'codo']

  # Publishing task.
  grunt.registerTask 'publish', ['default']

  # Standalone execution task.
  grunt.registerTask 'run', ['clean', 'compile', 'bgShell:run']