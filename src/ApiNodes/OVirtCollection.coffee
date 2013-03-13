"use strict"


{Mixins} = require 'coffee-mix'
Fiber = require 'fibers'
ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtCollection = class ApiNodes.OVirtCollection extends ApiNodes.OVirtApiNode
  # Included Mixins
  @include Mixins.Outgrowthable

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

  findAll: (callback) ->
    fiber = Fiber.current

    target = do @$outgrow
    @$connection.performRequest target, uri: @href, (err, entries) ->
      fiber.run(entries) if fiber?
      callback err, entries if callback?

    do Fiber.yield if fiber?

ApiNodes.OVirtApiNode.API_NODE_TYPES.collection = OVirtCollection

module.exports = OVirtCollection

