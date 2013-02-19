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
  # Static properties
  @SPECIAL_PROPERTIES = ['link', 'action', 'special_objects']
  @LINK_PROPERTY = 'link'
  @ACTION_PROPERTY = 'action'
  @ATTRIBUTE_KEY = '$'

  # Defaults
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
      throw new TypeError "Hydrator's target should be an OVirtApiNode instance"

  #
  # Hydrates hash to target.
  #
  # + Searches hash for collections and exports them to target.
  #
  hydrate: ->
    @exportCollections do @getHydratedCollections
    @exportProperties do @findProperties

  exportProperties: (properties) ->
    @target.properties = properties

  #
  # Exports specified collections to target.
  # By default uses instance target.
  #
  # @overload exportCollections(collections)
  #   @param collections [Object<OVirtCollection>] hash of collections
  #
  # @overload exportCollections(collections, target)
  #   @param collections [Object<OVirtCollection>] hash of collections
  #   @param target [OVirtApiNode] target API node
  #
  exportCollections: (collections, target) ->
    target = @target unless target
    target.collections = collections

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
  # Tests if specified value is a property key.
  #
  # @param name [String] supject name
  #
  # @return [Boolean]
  #
  isProperty: (name) ->
    (OVirtResponseHydrator.SPECIAL_PROPERTIES.indexOf name) < 0

  #
  # Returns href base for specified search pattern.
  #
  # @param href [String] serch option link "href" attribute
  #
  # @return [String] search href base or undefined
  #
  getSearchHrefBase: (href) ->
    matches = href.match /^([\w\/;{}=]+\?search=)/
    matches[1] if _.isArray(matches) and matches.length is 2

  #
  # Extracts first element of the collection search link 'rel' atribute.
  #
  # @param rel [String] rel attribute of the collection search link
  #
  # @return [String]
  #
  # @private
  #
  _getSearchOptionCollectionName: (rel) ->
    matches = rel.match /^(\w+)\/search$/
    matches[1] if _.isArray(matches) and matches.length is 2

  #
  # Extracts special object collection name from the 'rel' attribute.
  #
  # @param rel [String] rel attribute of the special object link
  #
  # @return [String]
  #
  # @private
  #
  _getSpecialObjectCollection: (rel) ->
    matches = rel.match /([\w\/]+)\/\w+$/
    matches[1] if _.isArray(matches) and matches.length is 2

  #
  # Extracts special object name from the 'rel' attribute.
  #
  # @param rel [String] rel attribute of the special object link
  #
  # @return [String]
  #
  # @private
  #
  _getSpecialObjectName: (rel) ->
    matches = rel.match /[\w\/]+\/(\w+)$/
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
      collections[key].searchOptions =
        href: searchabilities[key].href

  #
  # Adds special objects to corresponding collections.
  #
  # @param collections [Object<OVirtCollection>] collections hash
  # @param specialities [Object] collections special objects
  #
  # @private
  #
  _addSpecialObjects: (collections, specialities) ->
    try
      for object in specialities[0].link
        @_addSpecialObject collections, _.clone object

  #
  # Adds special object to exact collections.
  #
  # @param collections [OVirtCollection] collections hash
  # @param specialities [Object] collection special objects
  #
  # @private
  #
  _addSpecialObject: (collections, object) ->
    object = @_mergeAttributes object
    collection = @_getSpecialObjectCollection object.rel
    name = @_getSpecialObjectName object.rel

    if collections[collection]?
      collections[collection].addSpecialObject name, object.href

  #
  # Returns a hash of top-level collections with properly setup search
  # capabilities and special objects.
  #
  # @overload getHydratedCollections()
  #   Uses instance hash property as an input value.
  #
  # @overload getHydratedCollections(hash)
  #   Accepts hash as an argument
  #   @param hash [Object] hash
  #
  # @return [Object<OVirtCollection>] hash of collections
  #
  getHydratedCollections: (hash) ->
    hash = @_hash unless hash?
    hash = @getRootElement hash

    {collections, searchabilities} = @_findCollections hash

    @_setupCollections collections
    @_makeCollectionsSearchabe collections, searchabilities
    @_addSpecialObjects collections, hash.special_objects

    collections

  #
  # Replaces collections property hash with corresponding collection instances.
  #
  # @param hash [Object<String>] hash
  #
  # @return [Object<OVirtCollection>] hash of collections instances
  #
  # @private
  #
  _setupCollections: (collections) ->
    for name, href of collections
      collections[name] = new OVirtCollection name, href

  #
  # Returns top-level collections an their search options.
  #
  # The result is a hash with two properties: colections and searchabilities.
  #
  # @param hash [Object] hash
  #
  # @return [Object] hash of collections and their search options
  #
  # @private
  #
  _findCollections: (hash) ->
    list = hash[OVirtResponseHydrator.LINK_PROPERTY]
    collections = {}
    searchabilities = {}

    list = [] unless _.isArray list

    for entry in list when @isCollectionLink entry
      entry = @getRootElement entry
      name = entry.rel
      if @isSearchOption name
        name = @_getSearchOptionCollectionName name
        searchabilities[name] = entry
      else
        collections[name] = entry.href

    collections: collections
    searchabilities: searchabilities

  #
  # Return a hash of hydrated properties.
  #
  # @overload findProperties()
  #   Uses instance hash property as an input value.
  #
  # @overload findProperties(hash)
  #   Accepts hash as an argument
  #   @param hash [Object] hash
  #
  # @return [Object] hash of hydrated properties
  #
  findProperties: (hash) ->
    hash = @_hash unless hash?
    hash = @getRootElement hash
    properties = {}

    for name, value of hash when @isProperty name
      properties[name] = @hydrateProperty value

    @_mergeAttributes properties

    properties

  #
  # Hydrates specified array.
  # Unfolds singular array element.
  #
  # @param value [Array]
  #
  # @return [Array,mixed]
  #
  # @private
  #
  _hydrateArray: (subject) ->
    if subject.length is 1
      @hydrateProperty subject[0]
    else
      @hydrateProperty entry for entry in subject

  #
  # Merges attributes into element.
  # Attribute key is defined by {.ATTRIBUTE_KEY}
  #
  # @param value [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _mergeAttributes: (subject) ->
    key = OVirtResponseHydrator.ATTRIBUTE_KEY
    if subject[key]?
      _.merge subject, subject[key]
      delete subject[key]

    subject

  #
  # Removes special properties defined in {.SPECIAL_PROPERTIES}.
  #
  # @param value [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _removeSpecialProperties: (subject) ->
    for key in OVirtResponseHydrator.SPECIAL_PROPERTIES
      delete subject[key]
    subject

  #
  # Hydrates specified hash.
  #
  # @param value [Object]
  #
  # @return [mixed]
  #
  # @private
  #
  _hydrateHash: (subject) ->
    subject = @_mergeAttributes _.cloneDeep subject
    for name, value of subject
      subject[name] = @hydrateProperty value
    @_removeSpecialProperties subject

  #
  # Hydrates specified value.
  #
  # @param value [mixed]
  #
  # @return [mixed]
  #
  hydrateProperty: (value) ->
    if _.isArray value
      @_hydrateArray value
    else if _.isObject value
      @_hydrateHash value
    else
      value

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
    if keys.length is 1 and not _.isArray hash[keys[0]]
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