fs = require 'fs'
lazy = require 'lazy.js'
mongoose = require 'mongoose'
fibrous = require 'fibrous'
slugify = require 'slugify'

class Migrate
  constructor: (@opts, @model) ->
    unless @model?
      @opts.mongo = @opts.mongo() if typeof @opts.mongo is 'function'
      connection = mongoose.createConnection @opts.mongo

      schema = new mongoose.Schema
        name:  type: String, index: true, unique: true, required: true
        createdAt:  type: Date, default: Date.now

      @model = connection.model 'MigrationVersion', schema, 'migration_versions'

    @opts.template ?= """
      module.exports =
        requiresDowntime: FIXME # true or false

        up: (done) ->
          done()

        down: (done) ->
          throw new Error('irreversible migration')

        test: (done) ->
          console.log 'copying development to test'
          require('child_process').exec "mongo test --eval \"db.dropDatabase(); db.copyDatabase('development', 'test'); print('copied')\"", ->
            done()
    """

  getTemplate: (name) -> @opts.template

  log: ->

  error: (msg) ->
    throw new Error msg

  get: (name) ->
    name = name.replace /\.coffee$/, ''
    migration = require "#{@opts.path}/#{name}"
    migration.name = name
    migration

  # Check a migration has been run
  exists: fibrous (name) ->
    @model.sync.findOne({name})?

  test: (name) ->
    @log "Testing migration `#{name}`"
    @get(name).test()

  # Run one migration by name
  one: fibrous (name) ->
    @sync.all([name])

  # Run all provided migrations or all pending if not provided
  all: fibrous (migrations) ->
    migrations = @sync.pending() if !migrations?
    for name in migrations
      if @sync.exists(name)
        @error "`#{name}` has already been run"
        return false
      migration = @get(name)
      @log "Running migration `#{migration.name}`"
      migration.sync.up()
      @model.sync.create name: migration.name
    true

  down: fibrous ->
    version = @model.sync.findOne {}, {name: 1}, {sort: 'name': -1}
    migration = @get(version.name)
    @log "Reversing migration `#{migration.name}`"
    migration.sync.down()
    version.sync.remove()

  # Return a list of pending migrations
  pending: fibrous ->
    filenames = fs.sync.readdir(@opts.path).sort()
    names = lazy(filenames).map (filename) ->
      return unless (match = filename.match /^([^_].+)\.coffee$/)
      match[1]
    names = lazy(names).compact()
    run = (mv.name for mv in @model.sync.find())
    lazy(names).without(run).toArray()

  # Generate a stub migration file
  generate: fibrous (name) ->
    name = "#{slugify name, '_'}"
    timestamp = (new Date()).toISOString().replace /\D/g, ''
    filename = "#{@opts.path}/#{timestamp}_#{name}.#{@opts.ext or 'coffee'}"
    fs.sync.writeFile filename, @getTemplate name
    filename

module.exports = Migrate

