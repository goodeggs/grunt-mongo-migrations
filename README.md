<img src="http://gruntjs.com/img/grunt-logo.png" style="width: 100px; float: right"/>

<a href="https://david-dm.org/goodeggs/grunt-mongoose-migrate" title="Dependency status"><img src="https://david-dm.org/goodeggs/grunt-mongoose-migrate.png"/></a>

# Grunt Mongoose Migrate

A helper grunt task to manage Mongoose MongoDB database migrations.

# Usage Example

## Gruntfile

    module.exports = (grunt) ->
      grunt.loadNpmTasks 'grunt-mongoose-migrations'

      grunt.initConfig
        migrations:
          path: "#{__dirname}/migrations"
          template: grunt.file.read "#{__dirname}/migrations/_template.coffee"
          mongo: 'mongodb://localhost:12345'
          ext: "coffee" # default `coffee`

## _template.coffee

    module.exports =          
      requiresDowntime: FIXME # true or false

      up: (callback) ->
        callback()

      down: (callback) ->
        throw new Error('irreversible migration')

      test: ->
        describe 'up', ->
          before ->
          after ->
          it 'works'

### Downtime Management

`requiresDowntime` is an option that intentionaly set to invalid value so that developer has to fix it. The flag is meant for **your own** deployment pipeline to be aware that there's a migration that requires server down time.

## Tasks

* migrate:generate
* migrate:pending
* migrate:all
* migrate:one
* migrate:down

### migrate:generate

Will create a migration using template in the file name with a `[timestamp]_[name].[ext]`

    $> grunt migrate:generate --name=rename_created_on_to_created_at
    
    Running "migrate:generate" task
    >> Created `./migrations/20131108211056037_rename_created_on_to_created_at.coffee`

    Done, without errors.
    
### migrate:pending

Prints out a list of pending migrations 

    $> grunt migrate:pending
    
    Running "migrate:pending" task
    >> `20131108193444023_move_users` is pending (requires downtime)
    >> `20131108211056037_rename_created_on_to_created_at` is pending
    

### migrate:all

Runs all pending migrations.

    $> grunt migrate:all
    
    Running "migrate:all" task
    >> Running migration 20131108193444023_test1
    >> Running migration 20131108211056037_rename_created_on_to_created_at
    >> Finished migrations

    Done, without errors.

Running this again will do nothing because all migrations have been ran.

    $> grunt migrate:all
    
    Running "migrate:all" task
    >> Finished migrations

    Done, without errors.

### migrate:one

Runs specific migration by name. If it was already executed before, will generate an error.

    $> grunt migrate:one --name=rename_created_on_to_created_at
    
    Running "migrate:one" task
    >> Running migration 20131108211056037_rename_created_on_to_created_at
    >> Finished migrations

    Done, without errors.

### migrate:down

Attempts to 

# License

The MIT License (MIT)

Copyright (c) 2013 Good Eggs Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
