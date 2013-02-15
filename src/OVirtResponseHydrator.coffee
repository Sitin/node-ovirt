"use strict"

# Tools.
_ = require 'lodash'

# Dependencies.
OVirtApi = require __dirname + '/OVirtApi'
OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtCollection = require __dirname + '/OVirtCollection'
OVirtResource = require __dirname + '/OVirtResource'


class OVirtResponseHydrator
  _target: null
  _hash: {}

  #
  # Utility methods that help to create getters and setters.
  #
  get = (props) => @:: __defineGetter__ name, getter for name, getter of props
  set = (props) => @::__defineSetter__ name, setter for name, setter of props

  #
  # @property [OVirtApiNode] target API node
  #
  get target: -> @_target
  set target: (target) -> @_target = target

  #
  # @property [Object] oVirt hash
  #
  get hash: -> @_hash
  set hash: (hash) ->
    @_hash = hash

  #
  # Accepts hydration parameters.
  #
  # @param  target [OVirtApiNode] response subject
  # @param  hash [Object] oVirt response as a hash
  #
  # @throw ["Hydrator's target should be an OVirtApiNode instance"]
  #
  constructor: (@target, @hash) ->
    if not (target instanceof OVirtApiNode)
      throw "Hydrator's target should be an OVirtApiNode instance"

  hydrate: ->


  exportCollections: (list) ->


  isCollection: (subject) ->

  isSearchOption: (href) ->
    /\?search=/.test href

  getSearchOptionCollectionName: (str) ->
    matches = str.match /^(\w+)\/search$/
    matches[1] if _.isArray(matches) and matches.length is 2


  findArrayOfCollections: (hash) ->
    hash = @_hash unless hash?
    hash = @getRootElement hash
    list = {}
    searchables = {}

    if _.isArray hash.link
      list = hash.link

    for entry in list
      name = entry.$.rel
      href = entry.$.href
      if @isSearchOption href
        searchables
      else
        list.name new OVirtCollection name, href

  getRootElementName: (hash) ->
    hash = @_hash unless hash?
    keys = Object.keys(hash)
    if keys.length is 1
      hash[keys[0]]
    else
      undefined

  getRootElement: (hash) ->
    hash = @_hash unless hash?
    rootName = @getRootElementName hash
    hash = hash[rootName] if rootName
    hash


module.exports = OVirtResponseHydrator