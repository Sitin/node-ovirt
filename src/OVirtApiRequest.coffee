"use strict"


request = require 'request'
_ = require 'lodash'
{CoffeeMix} = require 'coffee-mix'
Mixins = require __dirname + '/Mixins/'


class OVirtApiRequest extends CoffeeMix
  # Included Mixins
  @include Mixins.PropertyDistributor

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

  # Defaults
  _connection: null
  _method: 'get'
  _uri: null

  get protocol: -> @connection.protocol
  get host: -> @connection.host
  get username: -> @connection.username
  get password: -> @connection.password
  get connection: -> @_connection
  get method: -> @_method
  get uri: -> if @_uri? then @_uri else @connection.uri

  constructor: (options) ->
    # Setup privates
    @setupPrivateProperties options

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

  call: (params, callback) ->
    # When params wasn't specified
    if typeof params is 'function'
      callback = params
      params = {}
    else
      params = {} unless params

    # Set defaults from instance state
    _.defaults params,
               method: 'get'
               protocol: @protocol
               uri: @uri
               host: @host

    # Construct request options
    options =
      url: "#{params.protocol}://#{params.host}/#{params.uri}"
      method: params.method
      headers:
        'Authorization': do @getAuthHeader

    @request options, callback


module.exports = OVirtApiRequest

