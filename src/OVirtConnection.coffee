"use strict"


_ = require 'lodash'

OVirtApiRequest = require __dirname + '/OVirtApiRequest'
OVirtResponseParser = require __dirname + '/OVirtResponseParser'
{OVirtApi} = require __dirname + '/ApiNodes/'
{CoffeeMix} = require 'coffee-mix'
{Document} = require 'libxmljs'
Mixins = require __dirname + '/Mixins/'


#
# This is an entry point object that represents a connection to the dedicated
# oVirt instance.
# The root API resource is available as an .api property.
#
class OVirtConnection extends CoffeeMix
  # Included Mixins
  @include Mixins.Fiberable, ['connect']
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
  # @note This method returns meaningfull results only inside of a fiber.
  #
  # @param callback [Function]
  #
  # @return [ApiNodes.OVirtApi] oVirt API root node
  #
  connect: (callback) ->
    @performRequest @api, callback

  #
  # Performs actions over oVirt resource.
  #
  # @param target [ApiNodes.OVirtApiNode] action target
  # @param action [ApiNodes.OVirtAction] action object
  # @param callback [Function]
  #
  # @return [ApiNodes.OVirtApiNode] current node or failure report
  #
  performAction: (target, action, callback) ->
    bodyDoc = new Document
    body = bodyDoc.node('action').toString()

    options =
      uri: action.href
      method: 'post'
      body: body

    @performRequest target, options, (error, response) =>
      if not error? and @isActionCompleted response
        response = target.$owner
      callback error, response

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
  performRequest: (target, options, callback) ->
    # Check for overloadings
    if _.isFunction options
      callback = options
      options = {}

    # Construnct options
    _.defaults options, uri: @uri
    options.connection = @

    request = new OVirtApiRequest options

    request.call (error, xml) =>
      unless error?
        @parseResponse target, xml, callback
      else
        callback error

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