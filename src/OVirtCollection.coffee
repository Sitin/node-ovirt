"use strict"


OVirtApiNode = require __dirname + '/OVirtApiNode'


class OVirtCollection extends OVirtApiNode
  _isSearchable: no

  #
  # Utility methods that help to create getters and setters.
  #
  get = (props) => @:: __defineGetter__ name, getter for name, getter of props
  set = (props) => @::__defineSetter__ name, setter for name, setter of props

  #
  # @property [Object] search options
  #
  get searchOptions: -> @_searchOptions
  set searchOptions: (options) ->
    @setSearchOptions options

  #
  # @property [Boolean] whether collection is searchable
  #
  get isSearchable: -> @_isSearchable

  setSearchOptions: (options) ->
    @_isSearchable = yes
    @_searchOptions = options


OVirtApiNode.API_NODE_TYPES.collection = OVirtCollection

module.exports = OVirtCollection

