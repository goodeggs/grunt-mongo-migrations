chai = require 'chai'
fibrous = require 'fibrous'
fs = require 'fs'
sinon = require 'sinon'

expect = chai.expect
chai.use require 'sinon-chai'
Migrate = require '../mongo_migrate.js'

class StubMigrationVersion
  @find: ->
  @findOne: ->
  @create: ->

describe 'grunt-mongoose-migrate', ->
  migrate = null

  before ->
    opts = path: __dirname
    migrate = new Migrate opts, StubMigrationVersion

  describe '.get', ->
    migration = null

    before ->
      migration = migrate.get 'migration'

    it 'loads ok', -> expect(migration).to.be.ok
    it 'has name', -> expect(migration.name).to.equal 'migration'

  describe '.exists', ->
    before fibrous ->
      sinon.stub StubMigrationVersion, 'findOne', ({name}, cb) ->
        cb null, if name is 'existing' then {name} else null

    after ->
      StubMigrationVersion.findOne.restore()

    it 'returns true for existing migration', fibrous ->
      expect(migrate.sync.exists 'existing').to.eql true

    it 'returns false for existing migration', fibrous ->
      expect(migrate.sync.exists 'non_existing').to.eql false

  describe '.test', ->
    migration = null

    before fibrous ->
      migration = test: sinon.spy (cb) -> cb()
      sinon.stub migrate, 'get', -> migration
      migrate.sync.test()

    after ->
      migrate.get.restore()

    it 'executes migration test', fibrous ->
      expect(migration.test).to.have.been.calledOnce

  describe '.one', ->
    migration = null

    before fibrous ->
      migration =
        name: 'pending_migration'
        up: sinon.spy (cb) -> cb()
      sinon.stub migrate, 'exists', (name, cb) -> cb null, false
      sinon.stub migrate, 'get', -> migration
      sinon.stub StubMigrationVersion, 'create', (args..., cb) -> cb()
      migrate.sync.one 'pending_migration'

    after ->
      StubMigrationVersion.create.restore()
      migrate.get.restore()
      migrate.exists.restore()

    it 'calls up on migration', fibrous ->
      expect(migration.up).to.have.been.calledOnce

    it 'saves new migration', fibrous ->
      expect(StubMigrationVersion.create).to.have.been.calledWithMatch name: 'pending_migration'

  describe '.all', ->
    migration = null

    describe 'migrating all pending', ->
      before fibrous ->
        migration =
          name: 'pending_migration'
          up: sinon.spy (cb) -> cb()
        sinon.stub migrate, 'pending', (cb) -> cb null, ['pending_migration']
        sinon.stub migrate, 'exists', (name, cb) -> cb null, false
        sinon.stub migrate, 'get', -> migration
        sinon.stub StubMigrationVersion, 'create', (args..., cb) -> cb()
        migrate.sync.all()

      after ->
        StubMigrationVersion.create.restore()
        migrate.pending.restore()
        migrate.get.restore()
        migrate.exists.restore()

      it 'calls up on migration', fibrous ->
        expect(migration.up).to.have.been.calledOnce

      it 'saves new migration', fibrous ->
        expect(StubMigrationVersion.create).to.have.been.calledWithMatch name: 'pending_migration'

    describe 'migrating existing migration', ->
      before fibrous ->
        migration =
          name: 'existing_migration'
          up: sinon.spy (cb) -> cb()
        sinon.stub migrate, 'pending', (cb) -> cb null, ['existing_migration']
        sinon.stub migrate, 'exists', (name, cb) -> cb null, true
        sinon.stub migrate, 'get', -> migration
        sinon.stub migrate, 'error'
        sinon.stub StubMigrationVersion, 'create', (args..., cb) -> cb()
        migrate.sync.all()

      after ->
        StubMigrationVersion.create.restore()
        migrate.error.restore()
        migrate.pending.restore()
        migrate.get.restore()
        migrate.exists.restore()

      it 'does not call up on migration', fibrous ->
        expect(migration.up).to.not.have.been.calledOnce

      it 'does not save new migration', fibrous ->
        expect(StubMigrationVersion.create).to.not.have.been.called

      it 'calls error', fibrous ->
        expect(migrate.error).to.have.been.calledOnce

  describe '.down', ->
    migration = null
    version = null

    before fibrous ->
      migration = down: sinon.spy (cb) -> cb()
      sinon.stub migrate, 'get', -> migration

      version =
        name: 'migration'
        remove: sinon.spy (cb) -> cb()

      sinon.stub StubMigrationVersion, 'findOne', (args..., cb) ->
        cb null, version

      migrate.sync.down()

    after ->
      StubMigrationVersion.findOne.restore()
      migrate.get.restore()

    it 'calls down on the migration', fibrous ->
      expect(migration.down).to.have.been.calledOnce

    it 'removes version', fibrous ->
      expect(version.remove).to.have.been.calledOnce

  describe '.pending', ->
    pending = null
    migrate = null

    _test = (ext) ->
      before fibrous ->
        migrate = new Migrate {path: __dirname, ext: ext}, StubMigrationVersion

        sinon.stub fs, 'readdir', (args..., cb) ->
          cb null, ["migration3.#{ext}", "migration2.#{ext}", "migration1.#{ext}"]

        sinon.stub StubMigrationVersion, 'find', (args..., cb) ->
          cb null, [name: 'migration1']

        pending = migrate.sync.pending()

      after ->
        fs.readdir.restore()
        StubMigrationVersion.find.restore()

      it 'returns pending migrations', fibrous ->
        expect(pending).to.eql ['migration2', 'migration3']

    describe "coffee-script", ->
      _test "coffee"

    describe "javascript", ->
      _test "js"

  describe '.generate', ->
    before fibrous ->
      sinon.stub fs, 'writeFile', (args..., cb) -> cb()
      migrate.sync.generate 'filename'

    after ->
      fs.writeFile.restore()

    it 'generates migration file', fibrous ->
      expect(fs.writeFile).to.have.been.calledWithMatch /^.*_filename/, /.+/

