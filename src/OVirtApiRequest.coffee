"use strict"


request = require 'request'
_ = require 'lodash'
{CoffeeMix} = require 'coffee-mix'
Mixins = require __dirname + '/Mixins/'
Errors = require __dirname + '/Errors/'


class OVirtApiRequest extends CoffeeMix
  # Included Mixins
  @include Mixins.PropertyDistributor

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

  # Constants
  SUCCESS_CODES: [200, 202]

  # Defaults
  _connection: null
  _method: 'get'
  _uri: null
  _body: null

  get protocol: -> @connection.protocol
  get host: -> @connection.host
  get username: -> @connection.username
  get password: -> @connection.password
  get connection: -> @_connection
  get method: -> @_method
  get uri: -> if @_uri? then @_uri else @connection.uri
  get body: -> @_body

  constructor: (options) ->
    # Setup privates
    @setupPrivateProperties options

  getAuthHeader: ->
    'Basic ' + new Buffer(@username + ":" + @password).toString "base64"

  request: (options, callback) ->
    request options, (error, response, body) =>
      if not error? and response.statusCode not in @SUCCESS_CODES
        error = new Errors.OperationError response.statusCode

      callback error, body

  call: (params, callback) ->
    # When params wasn't specified
    if typeof params is 'function'
      callback = params
      params = {}
    else
      params = {} unless params

    # Set defaults from instance state
    _.defaults params,
               method: @method
               protocol: @protocol
               uri: @uri
               host: @host
               body: @body

    # Construct request options
    options =
      url: "#{params.protocol}://#{params.host}/#{params.uri}"
      method: params.method
      body: params.body
      headers:
        'Authorization': do @getAuthHeader
        'Content-Type': 'application/xml'

    @request options, callback


module.exports = OVirtApiRequest

