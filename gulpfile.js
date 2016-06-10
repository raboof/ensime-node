var gulp = require('gulp');
var ts = require('gulp-typescript');
var merge = require('merge2');
var sourcemaps = require('gulp-sourcemaps');
var coffee = require('gulp-coffee');
var coffeelint = require('gulp-coffeelint');
var jasmine = require('gulp-jasmine');



var tsProject = ts.createProject('tsconfig.json');
gulp.task('compile-ts', function() {   
    var tsResult = tsProject.src() // instead of gulp.src(...) 
        .pipe(sourcemaps.init())
        .pipe(ts(tsProject));
 
    return merge([
        tsResult.dts
            .pipe(gulp.dest('release/definitions')),
        tsResult.js
            .pipe(sourcemaps.write()) 
            .pipe(gulp.dest('release/js'))
    ]); 
});

gulp.task('compile-coffee', function() {
    gulp.src('src/**/*.coffee')
    .pipe(sourcemaps.init())
    .pipe(coffee())
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('release/js'));
});

// Just copy js to dist folder
gulp.task('copy-js', function() {
    return gulp
        .src('./src/**/*.js')
        .pipe(gulp.dest('release/js'));
});

gulp.task('coffee-lint', function() {
    gulp.src('./src/*.coffee')
        .pipe(coffeelint())
        .pipe(coffeelint.reporter()) 
});

gulp.task('integration', ['build'], function() {
	gulp.src('./release/js/spec-integration/**/*.js').pipe(jasmine())
});

gulp.task('test', ['build'], function() {
	gulp.src('./release/js/spec/**/*.js').pipe(jasmine())
});

gulp.task('compile', ['compile-ts', 'compile-coffee']);
gulp.task('build', ['compile', 'copy-js']);
gulp.task('lint', ['coffee-lint']);

gulp.task('default', ['lint', 'build']);

gulp.task('watch', ['compile'], function() {
    gulp.watch('src/**/*.ts', ['compile-ts']);
    gulp.watch('src/**/*.coffee', ['compile-coffee']);
});
