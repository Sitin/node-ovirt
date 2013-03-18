"use strict"

# Tools.
xml2js = require 'xml2js'
libxmljs = require 'libxmljs'

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
  @include Mixins.ApiNodeTargetOwner

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

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
    do @attachDocument
    @parseXML (error) =>
      callback error, @target

  #
  # Attaches XML document model to target.
  #
  attachDocument: ->
    @target.$xmlDocument = libxmljs.parseXml @response

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


module.exports = OVirtResponseParser