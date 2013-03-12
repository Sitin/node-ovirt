"use strict"

# Tools.
xml2js = require 'xml2js'

# Dependencies.
config = require __dirname + '/config'
{CoffeeMix} = require 'coffee-mix'
Mixins = require __dirname + '/Mixins/'
{OVirtApiNode} = require __dirname + '/ApiNodes'
OVirtResponseHydrator = require __dirname + '/OVirtResponseHydrator'


# @include Mixins.PropertyDistributor
class OVirtResponseParser extends CoffeeMix
  # Included Mixins
  @include Mixins.PropertyDistributor

  # Hack that forces Codo to see properties
  get = @get
  set = @set

  # Defaults
  _target: null
  _response: ''
  _Hydrator: OVirtResponseHydrator
  _hydrator: null
  _parserOptions: config.parser

  #
  # @property [ApiNodes.OVirtApiNode] target API node
  #
  get target: -> @_target
  set target: (target) ->
    @setTarget target

  #
  # @property [String] oVirt response
  #
  get response: -> @_response
  set response: (response) ->
    @_response = response

  #
  # Accepts parsing parameters.
  #
  # @param options [Object] the options hash
  # @option options target [String, Function, OVirtApiNode] response subject
  # @option options response [String] oVirt XML response
  #
  constructor: (options) ->
    # Setup properties
    @setupExistedProperties options

    # Set validator to current instance #hydrate method
    @_parserOptions.validator = @hydrate

    # Instantiate parser
    @_parser = new xml2js.Parser @_parserOptions

    # Instantiate hydrator
    @_hydrator = new @_Hydrator @target

  #
  # Asynchroniously parses XML and then exports parse results.
  #
  # @param callback [Function] callback function
  #
  parse: (callback) ->
    @parseXML (error) =>
      callback error, @target

  #
  # Asynchroniously parses XML contained in the #response to the hash.
  #
  # @param callback [Function] callback function
  #
  parseXML: (callback) ->
    @_parser.parseString @response, (error) ->
      callback error

  #
  # Passes all parameters to {#hydrateNodeValue node hydrator function}.
  #
  # This functon is binded to current responce parser instance.
  #
  # @param params... [mixed] what ever
  #
  # @return [mixed] new node value
  #
  hydrate: (params...) =>
    @hydrateNodeValue params...

  #
  # Calls inner hydrator instance to convert node value if necessary.
  #
  # @param xpath [String] node's XPath
  # @param currentValue [undefined, mixed] current value of the node
  # @param newValue [mixed] node value
  #
  # @return [mixed] hydrated node value
  #
  hydrateNodeValue: (xpath, currentValue, newValue) ->
    @_hydrator.hydrate xpath, currentValue, newValue

  #
  # Sets current target.
  #
  # If target is a function the it considered as a constructor of the response
  # subject.
  #
  # If target is a string then it tries convert it to API node constructor
  # using {ApiNodes.OVirtApiNode API node's} types hash (API_NODE_TYPES).
  #
  # @param target [String, Function, ApiNodes.OVirtApiNode] response subject
  #
  # @throw [TypeError]
  #
  setTarget: (target) ->
    if typeof target is 'string'
      target = OVirtApiNode.API_NODE_TYPES[target]

    if typeof target is 'function'
      target = new target connection: @connection

    if not (target instanceof OVirtApiNode)
      throw new
        TypeError "OVirtResponseParser requires OVirtApiNode as a target"

    @_target = target


module.exports = OVirtResponseParser