module.exports = (grunt) ->
  migrate = ->
    require 'coffee-errors'
    Migrate = require '../mongo_migrate'

    grunt.config.requires 'migrations.path'
    grunt.config.requires 'migrations.mongo'

    class GruntMigrate extends Migrate
      log: -> grunt.log.ok arguments...
      error: -> grunt.fail.fatal arguments...

    new GruntMigrate grunt.config 'migrations'

  getName = ->
    {name} = grunt.cli.options
    return grunt.fail.fatal "Migration name must be specified with `#{"--name".bold}`" unless name?
    name

  grunt.registerTask 'migrate:generate', 'Create a new migration', ->
    done = @async()

    migrate().generate getName(), (err, filename) ->
      grunt.log.ok "Created `#{filename.blue}`" unless err?
      done err

  grunt.registerTask 'migrate:one', 'Run a migration.', ->
    done = @async()

    migrate().one getName(), (err) ->
      grunt.log.ok "Migrated `#{name.blue}`" unless err?
      done()

  grunt.registerTask 'migrate:test', 'Tests a migration.', ->
    done = @async()

    migrate().test getName(), (err) ->
      grunt.log.ok "Completed `#{name.blue}`" unless err?
      done()

  grunt.registerTask 'migrate:down', 'Revert the most recent migration', ->
    done = @async()

    migrate().down (err) ->
      grunt.log.ok 'Migrated down' unless err?
      done err

  grunt.registerTask 'migrate:pending', 'List all pending migrations', ->
    done = @async()
    migrate = migrate()

    migrate.pending (err, pending) ->
      unless err?
        grunt.log.ok 'No pending migrations' if pending.length == 0

        pending.forEach (name) ->
          grunt.log.ok "`#{name.blue}` is pending " + (migrate.get(name).requiresDowntime and "(requires downtime)".red.bold or '')

      done err

  grunt.registerTask 'migrate:all', 'Run all pending migrations', ->
    done = @async()

    migrate().all (err) ->
      grunt.log.ok 'Finished migrations' unless err?
      done err
