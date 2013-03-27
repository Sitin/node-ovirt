"use strict"


_ = require 'lodash'
Sync = require 'sync'

OVirtApiRequest = require __dirname + '/OVirtApiRequest'
OVirtResponseParser = require __dirname + '/OVirtResponseParser'
{OVirtApi, OVirtErrorNode} = require __dirname + '/ApiNodes/'
{CoffeeMix} = require 'coffee-mix'
{Document} = require 'libxmljs'
Errors = require __dirname + '/Errors/'
Mixins = require __dirname + '/Mixins/'


#
# This is an entry point object that represents a connection to the dedicated
# oVirt instance.
# The root API resource is available as an .api property.
#
class OVirtConnection extends CoffeeMix
  # Included Mixins
  @include Mixins.PropertyDistributor

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

  # Defaults.
  _protocol: 'https'
  _host: ''
  _uri: 'api'
  _username: null
  _password: null

  # This one is used to inject oVirt root resource class as a dependency.
  _OVirtApi: OVirtApi

  #
  # @property [OVirtApi] oVirt API root resource
  #
  get api: ->
    @_api = new @_OVirtApi $connection: @ unless @_api
    @_api

  #
  # @property [String] protocol, defaults to "https"
  #
  get protocol: -> @_protocol

  #
  # @property [String] oVirt manager host name
  #
  get host: -> @_host

  #
  # @property [String] oVirt API URI, defaults to "api"
  #
  get uri: -> @_uri

  #
  # @property [String]
  #
  get username: -> @_username

  #
  # @property [String]
  #
  get password: -> @_password

  #
  # Requires connection parameters.
  #
  # @param options [Object] the options hash
  # @option options protocol [String] protocol, defaults to "https"
  # @option options host [String] oVirt manager host name
  # @option options uri [String] oVirt API URI, defaults to "api"
  # @option options username [String]
  # @option options password [String]
  #
  constructor: (options) ->
    # Setup privates
    @setupPrivateProperties options

  #
  # Retrieves oVirt API {ApiNodes.OVirtApi root node}.
  #
  # @param worker [Function] function that will be executed in context of fiber
  # @param callback [Function] optional callback
  #
  # @return [OVirtConnection] current instance
  #
  connect: (worker, callback) ->
    Sync =>
      error = null

      try
        api = @performRequest @api
      catch error

      worker? error, api

    , callback

    @

  #
  # Performs actions over oVirt resource.
  #
  # @param target [ApiNodes.OVirtApiNode] action target
  # @param action [ApiNodes.OVirtAction] action object
  # @param callback [Function]
  #
  # @return [ApiNodes.OVirtApiNodem ApiNodes.OVirtApiNode] current node or
  #   failure report
  #
  performAction: (target, action, callback) ->
    bodyDoc = new Document
    body = bodyDoc.node('action').toString()

    options =
      uri: action.href
      method: 'post'
      body: body

    try
      result = @performRequest target, options
      if @isActionCompleted result
        result = target.$owner
    catch error

    callback? error, result

    result


  #
  # Performs add request to `href` with specified `body` and puts result to
  # target node.
  #
  # @param target [ApiNodes.OVirtApiNode] resource target
  # @param href [String] href to request
  # @param body [String] data to add
  # @param callback [Function]
  #
  # @return [ApiNodes.OVirtApiNode, ApiNodes.OVirtErrorNode] current node or
  #   failure report
  #
  add: (target, href, body, callback) ->
    options =
      uri: href
      method: 'post'
      body: body

    @performRequest target, options, callback

  #
  # Tests whether action was successfull.
  #
  # @param response [ApiNodes.OVirtApiNode] response node
  #
  # @return [Boolean]
  #
  isActionCompleted: (response) ->
    response?.status?.state is 'complete'

  #
  # Performs request to oVirt REST API.
  #
  # @overload performRequest(target, callback)
  #   @param target [ApiNodes.OVirtApiNode] request target
  #   @param callback [Function]
  #
  # @overload performRequest(target, options, callback)
  #   @param target [ApiNodes.OVirtApiNode] request target
  #   @param options [Object]
  #   @param callback [Function]
  #
  performRequestAsync: (target, options, callback) ->
    # Check for overloadings
    if _.isFunction options
      callback = options
      options = {}
    else
      options = {} unless options?

    # Construnct options
    _.defaults {}, options, uri: @uri
    options.connection = @

    request = new OVirtApiRequest options

    request.call (error, xml) =>
      # Set target to error node if server returns error.
      if error instanceof Errors.OVirtError
        target = new OVirtErrorNode
        error = null

      if not error?
        @parseResponse target, xml, callback
      else
        callback error, xml

  #
  # Performs request to oVirt REST API.
  #
  # @param target [ApiNodes.OVirtApiNode] request target
  # @param options [Object]
  #
  # @return [ApiNodes.OVirtApiNode]
  #
  performRequest: (target, options) ->
    @performRequestAsync.sync @, target, options

  #
  # Parses response
  #
  # @param target [ApiNodes.OVirtApiNode] request target
  # @param xml [Buffer, String]
  # @param callback [Function]
  #
  parseResponse: (target, xml, callback) ->
    parser = new OVirtResponseParser target: target, response: xml
    parser.parse callback


module.exports = OVirtConnection