"use strict"

# Tools.
_ = require 'lodash'

# Dependencies.
OVirtApi = require __dirname + '/OVirtApi'
OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtCollection = require __dirname + '/OVirtCollection'
OVirtResource = require __dirname + '/OVirtResource'

#
# This class hydrates oVirt API responses mapped to hashes by
# {OVirtResponseParser}.
#
# + It tries to find top-level collections links and exports them to target.
# - Tries to detect construct links to resources.
# - Investigates for embedded collections links and process them.
# - Exports all other "plain" properties as hashes.
#
# @todo Implement properties hydration
# @todo Deal with subcollections
# @todo Implement resource links hydration
#
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

  #
  # Hydrates hash to target.
  #
  # + Searches hash for collections and exports them to target.
  #
  hydrate: ->
    @exportCollections do @findCollections

  #
  # Exports specified collections to target.
  #
  # @param collections [Object<OVirtCollection>] hash of collections
  #
  exportCollections: (collections) ->
    @target.collections = collections

  #
  # Tests whether specified subject is a link to collection.
  #
  # @param subject [Object, Array] tested subject
  #
  # @return [Boolean] whether specified subject is a collection hash
  #
  isCollectionLink: (subject) ->
    return no unless @isLink subject
    subject = @getRootElement subject
    subject.rel? and not @isResourceLink subject

  #
  # Tests whether specified subject is a link to resource or collection.
  #
  # @param subject [Object, Array] tested subject
  #
  # @return [Boolean] whether specified subject is a link
  #
  isLink: (subject) ->
    subject = @getRootElement subject
    return no unless subject
    (subject.rel? or subject.id?) and subject.href?

  #
  # Tests whether specified subject is a link to resource.
  #
  # @param subject [Object, Array] tested subject
  #
  # @return [Boolean] whether specified subject is a resource link
  #
  isResourceLink: (subject) ->
    return no unless @isLink subject
    subject = @getRootElement subject
    return no unless subject
    /\w+-\w+-\w+-\w+-\w+$/.test subject.href


  #
  # Tests if value is a valid search option "rel" attribute.
  #
  # Rels with leading slashes treated as invalid.
  #
  # @param rel [String] link "rel" attribute
  #
  # @return [Boolean]
  #
  isSearchOption: (rel) ->
    /^\w+\/search$/.test rel

  #
  # Returns href base for specified search pattern.
  #
  # @param href [String] serch option link "href" attribute
  #
  # @return [String] search href base or undefined
  #
  getSearchHrefBase: (href) ->
    matches = href.match /^([\w\/]+\?search=)/
    matches[1] if _.isArray(matches) and matches.length is 2

  #
  # Extracts first element of the collection search link 'rel' atribute.
  #
  # @param rel [String] rel attribute of the collection search link
  #
  # @return [String]
  #
  getSearchOptionCollectionName: (rel) ->
    matches = rel.match /^(\w+)\/search$/
    matches[1] if _.isArray(matches) and matches.length is 2

  #
  # Passes searchabilities to exact collections.
  #
  # @param collections [Object<OVirtCollection>] collections hash
  # @param searchabilities [Object] search options for selected collections
  #
  # @private
  #
  _makeCollectionsSearchabe: (collections, searchabilities) ->
    for key of searchabilities
      collections[key].searchOptions = searchabilities[key]

  #
  # Returns a hash of top-level collections with properly setup search
  # capabilities.
  #
  # @overload findCollections()
  #   Uses instance hash property as an input value.
  #
  # @overload findCollections(hash)
  #   Accepts hash as an argument
  #   @param hash [Object] hash
  #
  # @return [Object<OVirtCollection>] hash of collections
  #
  findCollections: (hash) ->
    hash = @_hash unless hash?
    hash = @getRootElement hash
    list = []
    collections = {}
    searchabilities = {}

    if _.isArray hash.link
      list = hash.link

    for entry in list when @isCollectionLink entry
      entry = @getRootElement entry
      name = entry.rel
      if @isSearchOption name
        name = @getSearchOptionCollectionName name
        searchabilities[name] = entry
      else
        collections[name] = new OVirtCollection name, entry.href

    @_makeCollectionsSearchabe collections, searchabilities

    collections

  #
  # Returns the name of the hash's root key if exist.
  #
  # @overload getRootElementName()
  #   Uses instance hash property as an input value.
  #
  # @overload getRootElementName(hash)
  #   Accepts hash as an argument
  #   @param hash [Object] hash
  #
  # @return [String] hash root key or undefined
  #
  getRootElementName: (hash) ->
    hash = @_hash unless hash?
    return undefined unless hash?
    keys = Object.keys(hash)
    if keys.length is 1
      keys[0]
    else
      undefined

  #
  # Returns the value of the hash root element.
  #
  # @overload getRootElement()
  #   Uses instance hash property as an input value.
  #
  # @overload getRootElement(hash)
  #   Accepts hash as an argument
  #   @param hash [Object] hash
  #
  # @return [String] hash root key or undefined
  #
  getRootElement: (hash) ->
    hash = @_hash unless hash?
    return undefined unless hash?
    rootName = @getRootElementName hash
    hash = hash[rootName] if rootName
    hash


module.exports = OVirtResponseHydrator