"use strict"

# Tools.
xml2js = require 'xml2js'

# Dependencies.
OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtResponseHydrator = require __dirname + '/OVirtResponseHydrator'


class OVirtResponseParser
  _target: null
  _response: ''
  _OVirtResponseHydrator: OVirtResponseHydrator

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
    xml2js.parseString @response, (error, result) ->
      callback error, result

  #
  # Exports oVirt response that was represented as a hash.
  #
  # @private
  # @param hash [Object] oVirt response as a hash
  #
  _exportParseResults: (hash) ->
    hydrator = new @_OVirtResponseHydrator @target, hash
    do hydrator.hydrate

  #
  # Sets current target.
  #
  # If target is a function the it considered as a constructor of the response
  # subject.
  #
  # If target is a string then it tries convert it to API node constructor
  # using {OVirtApiNode.API_NODE_TYPES API node types hash}.
  #
  # @param target [String, Function, OVirtApiNode] response subject
  #
  # @throw ["OVirtResponseParser requires OVirtApiNode as a target"] on invalid target
  #
  setTarget: (target) ->
    if typeof target is 'string'
      target = OVirtApiNode.API_NODE_TYPES[target]

    if typeof target is 'function'
      target = new target connection: @connection

    if not (target instanceof OVirtApiNode)
      throw "OVirtResponseParser requires OVirtApiNode as a target"

    @_target = target


module.exports = OVirtResponseParser