"use strict"

# Tools.
xml2js = require 'xml2js'

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
  constructor: (@target, @hash) ->

  hydrate: ->


  exportCollections: (list) ->


  findArrayOfCollections: (hash) ->
    hash = @getHashRoot hash
    list = []

    if _.isArray hash.link
      list = hash.link

    for entry in list
      key = entry.$.rel
      uri = entry.$.href

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