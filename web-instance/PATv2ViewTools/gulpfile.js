var gulp = require('gulp');
var $ = require('gulp-load-plugins')();
var open = require('open'),
    run_env = require('./util').run_env(),
    server = require('./boot').server

var app = {
    rootPath:'/',
    srcPath: 'src/',
    devPath: "build/",
    prdPath: "dist/"
};
var port = 1337

var lib_path = ['node_modules/swig*/**/*',
    'bower_components/**/*'
];
gulp.task("lib", function () {
    lib(lib_path)
})

function lib(paths) {
    paths.forEach(element => {
        gulp.src(element)
            .pipe(gulp.dest(app.devPath + 'vendor'))
            .pipe(gulp.dest(app.prdPath + 'vendor'))
            .pipe($.connect.reload())
    });
}

var content_path = [app.srcPath + 'controllers*/**/*',
    app.srcPath + 'routes*/**/*',
    app.srcPath + 'models*/**/*',
    app.srcPath + 'middlewares*/**/*',
    app.srcPath + 'public*/utils*/**/*',
    app.srcPath + 'tests*/**/*'
];
gulp.task("content", function () {
    mv(content_path)
})

function mv(paths) {
    paths.forEach(element => {
        gulp.src(element)
            .pipe(gulp.dest(app.devPath))
            .pipe(gulp.dest(app.prdPath))
            .pipe($.connect.reload())
    });
}
gulp.task('view', function () {
    gulp.src('src/**/*.html')
        .pipe(gulp.dest(app.devPath))
        .pipe(gulp.dest(app.prdPath))
        .pipe($.connect.reload())
});

gulp.task('json', function () {
    gulp.src(app.srcPath + 'public/data/**/*.json')
        .pipe(gulp.dest(app.devPath + 'public/data'))
        .pipe(gulp.dest(app.prdPath + 'public/data'))
        .pipe($.connect.reload())
});

gulp.task('less', function () {
    gulp.src(app.srcPath + 'public/styles/*')
        .pipe($.less())
        .pipe(gulp.dest(app.devPath + 'public/styles'))
        .pipe($.cssmin())
        .pipe(gulp.dest(app.prdPath + 'public/styles'))
        .pipe($.connect.reload())
});

gulp.task('js', function () {
    gulp.src(app.srcPath + 'public/scripts/**/*.js')
        .pipe(gulp.dest(app.devPath + 'public/scripts'))
        .pipe($.uglify())
        .pipe(gulp.dest(app.prdPath + 'public/scripts'))
        .pipe($.connect.reload())
});

gulp.task('image', function () {
    gulp.src(app.srcPath + 'public/images/**/*')
        .pipe(gulp.dest(app.devPath + 'public/images'))
        .pipe($.imagemin())
        .pipe(gulp.dest(app.prdPath + 'public/images'))
        .pipe($.connect.reload())
});

gulp.task('clean', function () {
    gulp.src([app.devPath, app.prdPath])
        .pipe($.clean())
});

gulp.task('build', ['image', 'js', 'less', 'lib', 'view', 'json', 'content']);

gulp.task('default', ['server'])

gulp.task('server', ['build'], function () {
    var env = $.if(run_env === 'production', 'dist', 'build')
    console.log(env)
    $.connect.server({
        root: [env],
        livereload: true,
        port: port
    });

    server(port, env)
    open('http://127.0.0.1:' + port)

    gulp.watch(app.srcPath + 'public/images/**/*', ['image']);
    gulp.watch(app.srcPath + 'public/scripts/**/*.js', ['js']);
    gulp.watch(app.srcPath + 'public/styles/**/*', ['less']);
    gulp.watch(lib_path, ['lib']);
    gulp.watch(app.srcPath + '**/*.html', ['view']);
    gulp.watch(app.srcPath + 'public/data/**/*.json', ['json']);
    gulp.watch(content_path, ['content']);
});