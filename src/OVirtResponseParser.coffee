"use strict"

# Tools.
xml2js = require 'xml2js'

# Dependencies.
config = require __dirname + '/config'
OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtResponseHydrator = require __dirname + '/OVirtResponseHydrator'


class OVirtResponseParser
  # Defaults
  _target: null
  _response: ''
  _Hydrator: OVirtResponseHydrator
  _hydrator: null
  _parserOptions: config.parser

  #
  # Utility methods that help to create getters and setters.
  #
  get = (props) => @:: __defineGetter__ name, getter for name, getter of props
  set = (props) => @::__defineSetter__ name, setter for name, setter of props

  #
  # @property [OVirtApiNode] target API node
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
    # We need only properties those are in the prototype
    for key of options
      if typeof @['_' + key] isnt 'undefined'
        # Try to set via setter if exists:
        if typeof @__lookupSetter__(key) isnt 'function'
          @['_' + key] = options[key]
        else
          @[key] = options[key]

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
    @parseXML (error, result) =>
      @_exportParseResults result unless error
      callback error

  #
  # Asynchroniously parses XML contained in the #response to the hash.
  #
  # @param callback [Function] callback function
  #
  parseXML: (callback) ->
    @_parser.parseString @response, (error, result) ->
      callback error, result

  #
  # Passes all parameters to {#hydrateNode node hydrator function}.
  #
  # This functon is binded to current responce parser instance.
  #
  # @param params... [mixed] what ever
  #
  # @return [mixed] new node value
  #
  hydrate: (params...) =>
    @hydrateNode params...

  #
  # Calls inner hydrator instance to convert node value if necessary.
  #
  # @param xpath [String] node's XPath
  # @param currentValue [undefined, mixed] current value of the node
  # @param newValue [mixed] node value
  #
  # @return [mixed] hydrated node value
  #
  hydrateNode: (xpath, currentValue, newValue) ->
    @_hydrator.hydrateNode xpath, currentValue, newValue

  #
  # Sets current target.
  #
  # If target is a function the it considered as a constructor of the response
  # subject.
  #
  # If target is a string then it tries convert it to API node constructor
  # using {OVirtApiNode API node's} types hash (API_NODE_TYPES).
  #
  # @param target [String, Function, OVirtApiNode] response subject
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

  #
  # Exports oVirt response that was represented as a hash.
  #
  # @private
  # @param hash [Object] oVirt response as a hash
  #
  _exportParseResults: (hash) ->


module.exports = OVirtResponseParser