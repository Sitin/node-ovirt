"use strict"


{OVirtApi} = require __dirname + '/ApiNodes/'
{CoffeeMix} = require 'coffee-mix'
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


module.exports = OVirtConnection