_     = require 'lodash'
auth  = require 'basic-auth'
aws4  = require 'aws4'
url   = require 'url'
https = require 'https'
http  = require 'http'

DEFAULT_HOST = 'search-meshlastic-jzohajyndq6bowz24ic2jnf3vu.us-west-2.es.amazonaws.com'
OMITTED_HEADERS = ['x-uri', 'Authenticate', 'WWW-Authenticate', 'host']

class Router
  route: (app) =>
    app.all '*', (request, response) =>
      user = auth(request)
      return response.sendStatus(401) unless user?

      options =
        host:    request.get('X-Host') ? DEFAULT_HOST
        path:    request.path
        method:  request.method
        headers: _.omit request.headers, (value, key) => _.contains OMITTED_HEADERS, key.toLowerCase()
        body:    request.body

      upstreamRequest = http.request aws4.sign(options, accessKeyId: user.name, secretAccessKey: user.pass)

      upstreamRequest.once 'error', (error) =>
        response.status(502).send "Upstream Error: #{error.message}"

      upstreamRequest.once 'response', (res) =>
        body = ''

        res.on 'data', (data) =>
          body += data

        res.on 'end', =>
          response.status(res.statusCode).send JSON.parse(body)

      upstreamRequest.end options.body

module.exports = Router
