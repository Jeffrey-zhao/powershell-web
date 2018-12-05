var gulp = require("gulp"), //http://gulpjs.com/
    util = require("gulp-util"), //https://github.com/gulpjs/gulp-util
    scss = require("gulp-scss"), //https://www.npmjs.org/package/gulp-sass
    autoprefixer = require('gulp-autoprefixer'), //https://www.npmjs.org/package/gulp-autoprefixer
    minifycss = require('gulp-minify-css'), //https://www.npmjs.org/package/gulp-minify-css
    rename = require('gulp-rename'); //https://www.npmjs.org/package/gulp-rename

var scssFiles = "./scss/**/*"
gulp.task("scss", function () {
    gulp.src(scssFiles)
        .pipe(scss({
            'bundleExec': true
        }))
        .pipe(autoprefixer("last 3 version", "safari 5", "ie 8", "ie 9"))
        .pipe(gulp.dest("target/css"))
        .pipe(rename({
            suffix: '.min'
        }))
        .pipe(minifycss())
        .pipe(gulp.dest('target/css'));
});