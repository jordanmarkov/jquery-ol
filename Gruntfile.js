module.exports = function (grunt) {
    require('jit-grunt')(grunt);

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-newer');

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            compile: {
                options: {
                    compress: false,
                    strictUnits: true,
                    sourceMap: true,
                    sourceMapURL: "<%= pkg.name %>.css.map",
                    yuicompress: false,
                    optimization: 2
                },
                files: {
                    "dist/<%= pkg.name %>.css": "less/<%= pkg.name %>.less"
                }
            }
        },
        cssmin: {
            options: {
                shorthandCompacting: false,
                roundingPrecision: -1
            },
            target: {
                files: [{
                    expand: true,
                    cwd: 'dist',
                    src: ['*.css', '!*.min.css'],
                    dest: 'dist',
                    ext: '.min.css'
                }]
            }
        },
        coffee: {
            compile: {
                options: {
                    join: true,
                    bare: false,
                    sourceMap: true
                },
                files: {
                    'dist/<%= pkg.name %>.js': ['coffee/**/*.coffee']
                }
            }
        },
        uglify: {
            dist: {
                options: {
                    sourceMap: true,
                },
                files: {
                    'dist/<%= pkg.name %>.min.js': ['dist/<%= pkg.name %>.js']
                }
            }
        },
        clean: {
            css: 'dist/*.css',
            js: 'dist/*.js',
            map: 'dist/*.map',
        },
        watch: {
            css: {
                files: ['less/**/*.less'],
                tasks: ['clean:css', 'newer:less'],
                options: {
                    nospawn: true
                }
            },
            js: {
                files: ['coffee/**/*.coffee'],
                tasks: ['clean:js', 'coffee'],
                options: {
                    nospawn: true
                }
            }
        }
    });

    grunt.registerTask('default', [
        'prod'
    ]);

    grunt.registerTask('dev', [
        'newer:less',
        'newer:coffee',
    ]);

    grunt.registerTask('prod', [
        'dev',
        'newer:cssmin',
        'newer:uglify',
    ]);
};
