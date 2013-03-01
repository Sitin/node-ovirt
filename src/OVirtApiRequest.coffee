"use strict"


request = require 'request'
xml2js = require 'xml2js'
_ = require 'lodash'


class OVirtApiRequest
  protocol: 'https'
  host: ''
  uri: 'api'
  username: null
  password: null

  constructor: (options) ->
    # We need only properties those are in the prototype
    for key of options
      @[key] = options[key] if typeof @[key] isnt 'undefined'

  getAuthHeader: ->
    'Basic ' + new Buffer(@username + ":" + @password).toString "base64"

  request: (options, callback) ->
    request options, (error, response, body) ->
      if not error and response.statusCode is 200
        callback error, body
      else
        if error
          callback error
        else
          callback response.statusCode

  getRequestUri: (options) ->
    url = @uri

  call: (params, callback) ->
    if typeof params is 'function'
      callback = params
      params = {}
    else
      params = {} unless params
    _.defaults params, collection: '', method: 'get'

    options =
      url: "#{@protocol}://#{@host}/#{@uri}/#{params.collection}"
      method: params.method
      headers:
        'Authorization': do @getAuthHeader

    @request options, callback


module.exports = OVirtApiRequest

