"use strict"


querystring = require 'querystring'
_ = require 'lodash'
CoffeeMix = require 'coffee-mix'

ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
  OVirtResource: require __dirname + '/OVirtResource'
Mixins = require __dirname + '/../Mixins/'

{Document, Element} = require 'libxmljs'


OVirtCollection = class ApiNodes.OVirtCollection extends ApiNodes.OVirtApiNode
  # Included Mixins
  @include Mixins.Fiberable, ['add', 'findAll']
  @include CoffeeMix.Mixins.Outgrowthable

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

  # Defaults
  _isSearchable: no
  _searchOptions: {}
  _specialObjects: {}

  #
  # @property [Object] search options
  #
  get searchOptions: -> @_searchOptions
  set searchOptions: (options) ->
    @setSearchOptions options

  #
  # @property [Object] special objects
  #
  get specialObjects: -> @_specialObjects
  set specialObjects: (objects) ->
    @_specialObjects = objects

  #
  # @property [Boolean] whether collection is searchable
  #
  get isSearchable: -> @_isSearchable

  #
  # Sets search options.
  #
  # If search options are not empty then sets #isSearchable to true.
  #
  # @param options [Object] search options
  #
  setSearchOptions: (options) ->
    @_isSearchable = options?
    @_searchOptions = options

  #
  # Retrieves all collection objects.
  #
  # @note This method returns meaningfull results only inside of a fiber.
  #
  # @param callback [Function]
  #
  # @return [Array<ApiNodes.OVirtApiNode>]
  #
  getAll: (callback) ->
    @findAll null, callback

  #
  # Retrieves all collection objects that matches criteria.
  #
  # @note This method returns meaningfull resul ts only inside of a fiber.
  #
  # @param callback [Function]
  #
  # @return [Array<ApiNodes.OVirtApiNode>]
  #
  findAll: (criteria, callback) ->
    uri = @href

    if @isSearchable and not _.isEmpty criteria
      uri = @searchOptions.href
        .replace /{query}/, querystring.stringify criteria, '&', '%3D'

    target = do @$outgrow
    @$connection.performRequest target, uri: uri, (error, collection) =>
      # We want raw result in case of error
      unless error?
        # Properties are what we need
        entries = @_formatCollectionEntries collection

      callback error, entries if callback?

  #
  # Adds resource to collection.
  #
  # @note This method returns meaningfull results only inside of a fiber.
  #
  # @param properties [Object] object properties
  # @param apiNodes... [ApiNodes.OVirtApiNode] API nodes
  # @param callback [Function]
  #
  # @return [ApiNodes.OVirtApiNode]
  #
  add: (properties, apiNodes..., callback) ->
    type = @name.substring 0, @name.length - 1

    doc = new Document
    root = doc.node type
    root.node name, value for name, value of properties
    for node in apiNodes
      root.addChild node.$xmlDocument.root()

    target = new ApiNodes.OVirtResource $owner: @

    @$connection.add target, @href, doc.toString(), callback

  #
  # Formats collections entries.
  #
  # @param collection [ApiNodes.OVirtCollection]
  #
  # @return [Array] array of entries
  #
  # @private
  #
  _formatCollectionEntries: (collection) ->
    # Properties are what we need
    entries = collection.$properties

    # Unfold root element
    if Object.keys(entries).length is 1
      entries = entries[Object.keys(entries)[0]]

    # Empty array should represent epmty set
    entries = [] if _.isEmpty entries

    # Even singleton objects should be in array
    entries = [entries] unless _.isArray entries

    entries

ApiNodes.OVirtApiNode.API_NODE_TYPES.collection = OVirtCollection

module.exports = OVirtCollection

