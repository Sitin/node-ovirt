"use strict"

# Tools.
_ = require 'lodash'

# Dependencies.
config = require __dirname + '/config'
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
#
# Currently oVirt API responses has a following structure:
# ---------------------------------------------------------
#
# ### API
#
# * Collections (as a links)
# * Special objects (collection members with special rel's)
# * Links to resources (not in current version)
# * Properties
#
# ### Collections
#
# * Array of resources
#
# ### Resources
#
# * ID and hreg attributes that identifies resource
# * Subcollections (same as collections) as a links
# * Special objects as mentioned before.
# * Links to resources
# * Actions (special links).
# * Properties.
#
#
# Hydration tasks
# ----------------
# Assuming that collections and resource links and resources are top-level
# objects.
#
# ### Hydrate top level element attributes
#
# - Save attributes in corresponding property if existed.
#
# ### Hydrate collections
#
# + Collection links
#     + Detect whether specified node is a collection links.
#     + Instantiate collection objects.
#     + Save link to collection object in `_collections` property with `rel` as
#       a key in `<xpath>.instance` namespace.
#     + Set node value to undefined.
# + Search options
#     + Detect search option.
#     + Detect corresponding collection `rel`.
#     + Save search options in `_collections` with `rel` base as a key and
#       `<xpath>.searchOptions` as a namespace.
#     + Set node to undefined.
# - Special objects
#     - Detect special object.
#     - Detect special object related collection `rel`.
#     - Save a link to special object in `_collections` with `rel` base as a
#       key and `<xpath>.specialObjects` as a namespace.
#     - Set node to undefined.
# - Setup collections
#     - Detect that a set of the links are added to current node.
#     - Resolve collections namespace adding '/link' to current xpath.
#     - Loop over related search options if existed and setup corresponding
#       collections.
#     - Clean the applied `searchOptions` namespace.
#     - Loop over related special objects add links to them to corresponding
#       collections.
#     - Clean the applied `specialObjects` namespace.
# - Export collections (right after collections setup)
#     - If `link` is array then remove undefined values from it.
#     - Delete link if it is an epty array or is undefined.
#     - Loop over current `_collections` namespace
#     - Resolve collection name from `rel` key
#     - If current node isn't a root one then save link to collection object in
#       current node hash with collection name as a key.
#     - Otherwise export collection to target node.
#     - Clean current namespace of the `_collections` property.
#
# ### Hydrate resource links
#
# - Detect link to resource.
# - Instantiate resource objects in link mode.
# - Save results in resource links property.
#
# ### Hydrate resources
#
# - Detect resources.
# - Delegate resource hydration to other hydrator instance.
# - Save results in resources property.
#
# ### Hydrate actions
#
# - Detect actions
# - Instantiates actions objects
#
# ### Hydrate properties
#
# - Detect properties
# - Save them in corresponding property.
#
#
# Export tasks
# -------------
#
# - Export attributes.
# - Export collections.
# - Export resources.
# - Export resource links.
# - Export properties.
#
#
# Utility tasks
# --------------
#
# + Target setter should be able to create targets from strings and
# constructor function.
# + Get element attributes for custom hash.
# + Detect whether element has attributes.
# + Detect whether element has children.
# + Retrieve element's children (but not attributes).
# + Merge attributes with children (for plain properties).
# + Retrieve merged version of element (children with attributes).
# + Detect whether element is a link (it has href and id or rel property).
# + Detects whether string is a resource URI.
# + Detect whether element is a resource link (it has a resource href).
# + Detect collection links.
# + Detect resources.
# + Unfold element's root node contents.
#
class OVirtResponseHydrator
  # Static properties
  SPECIAL_PROPERTIES: config.api.specialProperties
  LINK_PROPERTY: config.api.link
  ACTION_PROPERTY: config.api.action
  ATTRIBUTE_KEY: config.parser.attrkey
  CHILDREN_KEY: config.parser.childkey
  SPECIAL_OBJECTS: config.api.specialObjects

  #
  # Utility methods that help to create getters and setters.
  #
  get = (props) => @:: __defineGetter__ name, getter for name, getter of props
  set = (props) => @::__defineSetter__ name, setter for name, setter of props

  #
  # @property [OVirtApiNode] target API node
  #
  get target: -> @_target
  set target: (target) ->
    @setTarget target

  #
  # @property [Object] oVirt hash
  #
  get hash: -> @_hash
  set hash: (hash) ->
    @_hash = hash

  #
  # Sets current target.
  #
  # If target is a function the it considered as a constructor of the response
  # subject.
  #
  # If target is a string then it tries convert it to API node constructor
  # using {OVirtApiNode API node's} types hash (API_NODE_TYPES).
  #
  # @param target [String, Function, OVirtApiNode] response subject
  #
  # @throw [TypeError]
  #
  setTarget: (target) ->
    if typeof target is 'string'
      target = OVirtApiNode.API_NODE_TYPES[target]

    if typeof target is 'function'
      target = new target connection: @connection

    if not (target instanceof OVirtApiNode)
      throw new
      TypeError "Hydrator's target should be an OVirtApiNode instance"

    @_target = target

  #
  # Accepts hydration parameters.
  #
  # @param  target [OVirtApiNode] response subject
  # @param  hash [Object] oVirt response as a hash
  #
  # @throw ["Hydrator's target should be an OVirtApiNode instance"]
  #
  constructor: (@target, @hash={}) ->
    @_collections = {}

  #
  # Hydrates node value if necessary.
  #
  # @param xpath [String] node's XPath
  # @param currentValue [undefined, mixed] current value of the node
  # @param newValue [mixed] node value
  #
  # @return [mixed] hydrated node value
  #
  hydrateNode: (xpath, currentValue, newValue) ->
    if @isCollectionLink newValue
      @hydrateCollectionLink xpath, newValue
      undefined
    else if @isSearchOption newValue
      @hydrateSearchOption xpath, newValue
      undefined
    else
      newValue

  #
  # Hydrates collection link.
  #
  # Registers link to created object in `_collections` hash under
  # `<xpath>.instance` namespace with a <rel> as a key.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [OVirtCollection] hydrated collection link
  #
  hydrateCollectionLink: (xpath, node) ->
    attributes = @_getAttributes node
    collection = new OVirtCollection attributes
    @registerIn @_collections, xpath, 'instances', attributes.rel, collection

    collection

  #
  # Hydrates collection collection search option.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [Object] hydrated search option
  #
  hydrateSearchOption: (xpath, node) ->
    searchOptions = @_getAttributes node
    name = @_getSearchOptionCollectionName searchOptions.rel
    @registerIn @_collections, xpath, 'searchOptions', name, searchOptions

    searchOptions

  #
  # Registers subject in proper namespace.
  #
  # @overload registerIn(nsPath..., subject)
  #   @param nsPath... [Array<String>] path to namespace for the current instance
  #   @param subject [mixed]
  #
  # @overload registerIn(hash, nsPath..., subject)
  #   @param hash [Object] root namespace hash
  #   @param nsPath... [Array<String>] path to namespace for the hash
  #   @param subject [mixed]
  #
  registerIn: (hash, nsPath..., subject) ->
    unless subject? and hash?
      throw new Error "You should specify both property and value to register in"

    if _.isString hash
      ns = @
      nsPath = [hash].concat nsPath
    else
      if nsPath.length is 0
        throw new Error "You should specify a namespace to register in existing object"
      ns = hash

    for key in _.initial nsPath
      ns[key] = {} unless ns[key]?
      throw new Error "Wrong namespace to register in" unless _.isObject ns[key]
      ns = ns[key]

    if nsPath.length > 0
      key = _.last nsPath
      ns[key] = subject
    else
      ns = subject

  #
  # Exports properties to target API node
  #
  # @param properties [Object] properties to export
  #
  exportProperties: (properties) ->
    @target.properties = properties

  #
  # Tests whether specified subject is a link to resource or collection.
  #
  # @param subject [Object, Array] tested subject
  #
  # @return [Boolean] whether specified subject is a link
  #
  isLink: (subject) ->
    attributes = @_getAttributes subject
    return no unless attributes
    (attributes.rel? or attributes.id?) and attributes.href?

  #
  # Tests whether specified subject is a link to collection.
  #
  # @param subject [Object, Array] tested subject
  #
  # @return [Boolean] whether specified subject is a collection hash
  #
  isCollectionLink: (subject) ->
    return no unless @isLink subject
    attributes = @_getAttributes subject
    attributes.rel? and not @_isResourceHref attributes.href

  #
  # Tests whether specified subject is a link to resource.
  #
  # @param subject [Object] tested subject
  #
  # @return [Boolean] whether specified subject is a resource link
  #
  isResourceLink: (subject) ->
    return no unless @_isResourceRelated subject
    not @_hasChildElements subject

  #
  # Tests whether specified subject is a resource hash representation.
  #
  # @param subject [Object] tested subject
  #
  # @return [Boolean] whether specified subject is a resource link
  #
  isResource: (subject) ->
    return no unless @_isResourceRelated subject
    @_hasChildElements subject

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
  # Tests whether specified subject is an element related to resource
  # or resource link.
  #
  # @param subject [Object] tested subject
  #
  # @return [Boolean] whether specified subject is a resource or resource link
  #
  # @private
  #
  _isResourceRelated: (subject) ->
    return no unless @isLink subject
    attributes = @_getAttributes subject
    @_isResourceHref attributes.href

  #
  # Tests whether specified string is a href to resource.
  #
  # @param subject [String] tested string
  #
  # @return [Boolean]
  #
  # @private
  #
  _isResourceHref: (subject) ->
    /[\w\/]+\/\w+-\w+-\w+-\w+-\w+$/.test subject

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
  # Extracts first element of the collection search link `rel` atribute.
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
    if _.isArray specialities.link
      for object in specialities.link
        @_addSpecialObject collections, _.clone object
    else if _.isObject specialities.link
      @_addSpecialObject collections, _.clone specialities.link

  #
  # Adds special object to exact collections.
  #
  # @param collections [OVirtCollection] collections hash
  # @param specialities [Object] collection special objects
  #
  # @private
  #
  _addSpecialObject: (collections, object) ->
    attributes = @_getAttributes object
    collection = @_getSpecialObjectCollection attributes.rel
    name = @_getSpecialObjectName attributes.rel

    if collections[collection]?
      # @todo Invoke proper OVirtApiCollection method
      collections[collection].specialObjects = name: name, href: attributes.href

  #
  # Returns collections special objects of response hash.
  #
  # @param hash [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _getSpecialObjects: (hash) ->
    hash[@SPECIAL_OBJECTS]

  #
  # Merges attributes into element.
  # Attribute key is defined by {#ATTRIBUTE_KEY}
  #
  # @param subject [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _mergeAttributes: (subject) ->
    if not (_.isObject subject) or _.isArray subject
      return undefined

    key = @ATTRIBUTE_KEY
    _.merge subject, @_getAttributes subject
    delete subject[key]

    subject

  #
  # Returns element version where all attributes are merged with children.
  # Attribute key is defined by {#ATTRIBUTE_KEY}
  #
  # @param subject [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _getPlainedElement: (subject) ->
    @_mergeAttributes _.clone subject

  #
  # Returns element attributes.
  # Attribute key is defined by {#ATTRIBUTE_KEY}
  #
  # @param subject [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _getAttributes: (subject) ->
    if not (_.isObject subject) or _.isArray subject
      return undefined

    key = @ATTRIBUTE_KEY
    if subject[key]?
      subject[key]
    else
      {}

  #
  # Returns whether element has attributes.
  #
  # @param subject [Object]
  #
  # @return [Boolean]
  #
  # @private
  #
  _hasAttributes: (subject) ->
    if not (_.isObject subject) or _.isArray subject
      return undefined

    keys = Object.keys subject
    _.contains keys, @ATTRIBUTE_KEY

  #
  # Returns whether element has children.
  # Attributes are not considered as a children.
  #
  # @param subject [Object]
  #
  # @return [Boolean]
  #
  # @private
  #
  _hasChildElements: (subject) ->
    if not (_.isObject subject) or _.isArray subject
      return undefined

    keys = Object.keys subject
    count = keys.length
    count-- if _.contains keys, @ATTRIBUTE_KEY

    count > 0

  #
  # Retrieves element's children.
  # Attributes are not considered as a children.
  #
  # @param subject [Object]
  #
  # @return [Object]
  #
  # @private
  #
  _getElementChildren: (subject) ->
    if not (_.isObject subject) or _.isArray subject
      return undefined

    _.omit subject, @ATTRIBUTE_KEY

  #
  # Converts hash to resource.
  #
  # @param value [Object]
  #
  # @return [<OVirtResource>]
  #
  # @private
  #
  _setupResourceLink: (hash) ->
    new OVirtResource @_mergeAttributes _.clone hash

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
    return undefined unless _.isObject hash
    keys = Object.keys(hash)
    if keys.length is 1 and not _.isArray hash[keys[0]]
      keys[0]
    else
      undefined

  #
  # Returns the value of the hash root element if existed.
  #
  # @overload unfolded()
  #   Uses instance hash property as an input value.
  #
  # @overload unfolded(hash)
  #   Accepts hash as an argument
  #   @param hash [mixed] hash
  #
  # @return [mixed] hash root key or undefined
  #
  unfolded: (hash) ->
    hash = @_hash unless hash?
    return undefined unless hash?
    rootName = @getRootElementName hash
    hash = hash[rootName] if rootName
    hash


module.exports = OVirtResponseHydrator