_     = require 'lodash'
auth  = require 'basic-auth'
aws4  = require 'aws4'
url   = require 'url'
https = require 'https'
http  = require 'http'
debug = require('debug')('aws-iam:router')

DEFAULT_HOST = 'search-meshlastic-jzohajyndq6bowz24ic2jnf3vu.us-west-2.es.amazonaws.com'

class Router
  route: (app) =>
    app.all '*', (request, response) =>
      user = auth(request)
      return response.sendStatus(401) unless user?

      body = request.body
      body = undefined unless _.isString body

      options =
        host:    request.get('X-Host') ? DEFAULT_HOST
        path:    request.path
        method:  request.method
        headers:
          'accept':       request.get('accept') ? 'application/json'
          'content-type': request.get('content-type') ? 'application/json'
          'connection':   'close'
        body:    body

      debug 'aws4.sign', options, accessKeyId: user.name, secretAccessKey: user.pass
      options = aws4.sign(options, accessKeyId: user.name, secretAccessKey: user.pass)
      debug 'http.request', options
      upstreamRequest = http.request options

      upstreamRequest.once 'error', (error) =>
        response.status(502).send "Upstream Error: #{error.message}"

      upstreamRequest.once 'response', (res) =>
        body = ''

        res.on 'data', (data) =>
          body += data

        res.on 'end', =>
          debug 'end', res.statusCode, JSON.parse(body)
          response.status(res.statusCode).send JSON.parse(body)

      upstreamRequest.end options.body

module.exports = Router
