"use strict"


querystring = require 'querystring'

_ = require 'lodash'
CoffeeMix = require 'coffee-mix'

Mixins = require __dirname + '/../Mixins/'
ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtCollection = class ApiNodes.OVirtCollection extends ApiNodes.OVirtApiNode
  # Included Mixins
  @include Mixins.Fiberable, ['findAll']
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
  # @note This method returns meaningfull results only inside of a fiber.
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
    @$connection.performRequest target, uri: uri, (error, entries) ->
      # We want raw result in case of error
      unless error?
        # Properties are what we need
        entries = entries.$properties

        # Unfold root element
        if Object.keys(entries).length is 1
          entries = entries[Object.keys(entries)[0]]

        # Empty array should represent epmty set
        entries = [] if _.isEmpty entries

        # Even singleton objects should be in array
        entries = [entries] unless _.isArray entries

      callback error, entries if callback?

ApiNodes.OVirtApiNode.API_NODE_TYPES.collection = OVirtCollection

module.exports = OVirtCollection

