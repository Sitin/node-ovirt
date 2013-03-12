"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtCollection = class ApiNodes.OVirtCollection extends ApiNodes.OVirtApiNode
  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

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

  constructor: ->
    @_isSearchable = no
    @_searchOptions = {}
    @_specialObjects = {}

  setSearchOptions: (options) ->
    @_isSearchable = yes
    @_searchOptions = options


ApiNodes.OVirtApiNode.API_NODE_TYPES.collection = OVirtCollection

module.exports = OVirtCollection

