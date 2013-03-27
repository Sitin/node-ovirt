"use strict"


_ = require 'lodash'
querystring = require 'querystring'

CoffeeMix = require 'coffee-mix'

ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
  OVirtResource: require __dirname + '/OVirtResource'

{Document, Element} = require 'libxmljs'


OVirtCollection = class ApiNodes.OVirtCollection extends ApiNodes.OVirtApiNode
  # Included Mixins
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
  # @return [Array<ApiNodes.OVirtApiNode>]
  #
  getAll: ->
    @findAll()

  #
  # Retrieves all collection objects that matches criteria.
  #
  # @param criteria [Object] search criteria
  #
  # @return [Array<ApiNodes.OVirtApiNode>]
  #
  findAll: (criteria) ->
    uri = @href

    if @isSearchable and not _.isEmpty criteria
      uri = @searchOptions.href
        .replace /{query}/, querystring.stringify criteria, '&', '%3D'

    target = do @$outgrow
    try
      collection = @$connection.performRequest target, uri: uri
      entries = @_formatCollectionEntries collection

    entries

  #
  # Adds resource to collection.
  #
  # @param properties [Object] object properties
  # @param apiNodes... [ApiNodes.OVirtApiNode] API nodes
  #
  # @return [ApiNodes.OVirtApiNode] created node
  #
  add: (properties, apiNodes...) ->
    type = @name.substring 0, @name.length - 1

    doc = new Document
    root = doc.node type
    root.node name, value for name, value of properties
    for node in apiNodes
      root.addChild node.$xmlDocument.root()

    target = new ApiNodes.OVirtResource $owner: @

    @$connection.add target, @href, doc.toString()

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

