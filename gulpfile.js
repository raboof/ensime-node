var gulp = require('gulp');
var ts = require('gulp-typescript');
var merge = require('merge2');
var sourcemaps = require('gulp-sourcemaps');
var coffee = require('gulp-coffee');
var coffeelint = require('gulp-coffeelint');
var jasmine = require('gulp-jasmine');
var rimraf = require('rimraf');
var runSequence = require('run-sequence');
var tsProject = ts.createProject('tsconfig.json');

function compileTs() {
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
}

gulp.task('compile-ts', compileTs);

gulp.task('compile-coffee', function() {
    return gulp.src('src/**/*.coffee')
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
        .pipe(coffeelint.reporter());
});

gulp.task('integration', ['build', 'it'], function() {
});

gulp.task('it', function() {
	gulp.src('./release/js/spec-integration/**/*.js').pipe(jasmine());
});

gulp.task('test', function() {
    console.log("starting tests…");
	return gulp.src('./release/js/spec/**/*.js').pipe(jasmine());
});

gulp.task('compile', ['compile-ts', 'compile-coffee']);
gulp.task('build', ['compile', 'copy-js']);
gulp.task('lint', ['coffee-lint']);

gulp.task('clean', function(cb) {
    return rimraf('./release', cb);
});


gulp.task('default', function(cb) {
    runSequence(['clean, build'], cb);
});

gulp.task('watch', ['build'], function() {
    gulp.watch('src/**/*.ts', function(cb) {
        runSequence('compile-ts', 'test');
    });
    gulp.watch('src/**/*.coffee', function(cb) {
        runSequence('compile-coffee', 'test');
    });
});
