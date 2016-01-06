_     = require 'lodash'
aws4  = require 'aws4'
url   = require 'url'
https = require 'https'
http  = require 'http'

OMITTED_HEADERS = ['x-uri', 'x-accesskeyid', 'x-secretaccesskey', 'host']

class Router
  route: (app) =>
    app.all '*', (request, response) =>
      return response.status(400).send 'Missing X-Host' unless request.get 'X-Uri'
      return response.status(400).send 'Missing X-AccessKeyId' unless request.get 'X-AccessKeyId'
      return response.status(400).send 'Missing X-SecretAccessKey' unless request.get 'X-SecretAccessKey'

      uri             = request.get 'X-Uri'
      accessKeyId     = request.get 'X-AccessKeyId'
      secretAccessKey = request.get 'X-SecretAccessKey'

      {hostname,pathname} = url.parse uri

      headers = _.omit request.headers, (value, key) => _.contains OMITTED_HEADERS, key.toLowerCase()

      options =
        host:    hostname
        path:    pathname
        method:  request.method
        headers: headers
        body:    request.body

      options = aws4.sign options, {accessKeyId, secretAccessKey}

      upstreamRequest = http.request options

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
