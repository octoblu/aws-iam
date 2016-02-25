bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
express            = require 'express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
morgan             = require 'morgan'
Router = require './router'

class Server
  constructor: ({@port}) ->

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev'
    app.use errorHandler()
    app.use bodyParser.text(limit: '5mb', type: '*/*')

    router = new Router {}

    router.route app

    @server = app.listen @port, callback


module.exports = Server
