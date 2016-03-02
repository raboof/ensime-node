module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      glob_to_multiple:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'lib'
        ext: '.js'

    coffeelint:
      options:
        no_empty_param_list:
          level: 'error'
        max_line_length:
          level: 'ignore'
        indentation:
          level: 'ignore'

      src: ['src/*.coffee']
      test: ['spec/*.coffee']
      gruntfile: ['Gruntfile.coffee']
    
    copy:
      main:
        expand: true
        cwd: 'src'
        src: '**/*.js'
        dest: 'lib/'

    shell:
      test:
        command: 'node --harmony node_modules/.bin/jasmine-focused --coffee --captureExceptions --forceexit spec'
        options:
          stdout: true
          stderr: true
          failOnError: true
      
      integration:
        command: 'node --harmony node_modules/.bin/jasmine-focused --coffee --captureExceptions --verbose --forceexit spec-integration'
        options:
          stdout: true
          stderr: true
          failOnError: true
          execOptions:
            maxBuffer: 500*1024
    
    watch:
      files: ['**/*.coffee'],
      tasks: ['lint', 'coffee']
    


  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-shell')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-copy')
  
  grunt.registerTask 'clean', ->
    require('rimraf').sync('lib')

  grunt.registerTask('lint', ['coffeelint'])
  grunt.registerTask('default', ['lint', 'copy', 'coffee'])
  grunt.registerTask('test', ['copy', 'coffee', 'lint', 'shell:test', 'shell:integration'])
  grunt.registerTask('integration', ['copy', 'coffee', 'lint', 'shell:integration'])
  grunt.registerTask('prepublish', ['clean', 'lint', 'copy', 'coffee', 'test', ['integration']])
