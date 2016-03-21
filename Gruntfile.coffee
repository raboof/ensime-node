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
        
    ts:
      default:
        tsconfig: true
        # src: ["src/**/*.ts"]
        # outDir: "lib"
        # baseDir: "lib"
        options:
          compiler: './node_modules/typescript/bin/tsc'
          module: 'commonjs'
          mapRoot: '/maps'
      
      dev:
        tsconfig: true
        options:
          compiler: './node_modules/typescript/bin/tsc'
          module: 'commonjs'
          mapRoot: '/maps'
        watch: "src/**/*.ts"

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
      typings:
        command: './node_modules/.bin/typings install'
      
      integration:
        command: 'node --harmony node_modules/.bin/jasmine-focused --coffee --captureExceptions --forceexit spec-integration'
        options:
          stdout: true
          stderr: true
          failOnError: true
          execOptions:
            maxBuffer: 500*1024
    
    watch:
      files: ['**/*.coffee'],
      tasks: ['lint', 'coffee', 'test']
    


  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-ts')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-shell')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-copy')
  
  grunt.registerTask 'clean', ->
    require('rimraf').sync('lib')

  grunt.registerTask('lint', ['coffeelint'])
  grunt.registerTask('build', ['shell:typings', 'lint', 'copy', 'ts:default', 'coffee'])
  grunt.registerTask('default', ['build'])
  grunt.registerTask('test', ['build', 'shell:test'])
  grunt.registerTask('it', ['build', 'shell:integration'])
  grunt.registerTask('prepublish', ['clean', 'build', 'test', 'it'])
