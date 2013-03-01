"use strict"

# Tools.
_ = require 'lodash'
path = require 'path'

# Dependencies.
config = require __dirname + '/config'
OVirtAction = require __dirname + '/OVirtAction'
OVirtApi = require __dirname + '/OVirtApi'
OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtCollection = require __dirname + '/OVirtCollection'
OVirtResource = require __dirname + '/OVirtResource'

#
# This class hydrates oVirt API responses mapped to hashes by
# {OVirtResponseParser}.
#
# + It tries to find top-level collections links and exports them to target.
# + Tries to detect and construct links to resources.
# + Investigates for embedded collections links and process them.
# + Exports all other "plain" properties as hashes.
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
# * ID and href attributes that identifies resource
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
# + Save attributes in corresponding property if existed.
#
# ### High level objects hydration.
#
# + Detect current hydration target.
#     + If current node is a root one then current target should be a hydrator
#       instance target.
#     - If current node is an owner of collections, resource links or actions
#       (except the case when the node is a resource)then an API node instance
#       should be created and set as a current target.
#     + If node is a resource then new resource object instance should be
#       created.
# + Extract attributes from node hash to current target.
# + Remove attributes from node hash.
# + Treat remaining node hash as a properties and export them to the current
#   target.
# + Finally we should replace node value with current target (if exists).
#
# ### Hydrate collections
#
# + Collection links
#     + Detect whether specified node is a collection links.
#     + Instantiate collection objects.
#     + Save link to collection object in `_collections` property with `rel` as
#       a key in `<parent element xpath>.instance` namespace.
#     + Set node value to undefined.
# + Search options
#     + Detect search option.
#     + Detect corresponding collection `rel`.
#     + Save search options in `_collections` with `rel` base as a key and
#       `<parent element xpath>.searchOptions` as a namespace.
#     + Set node to undefined.
# + Special objects
#     + Detect special object.
#     + Detect special object related collection `rel`.
#     + Detect special object name.
#     + Save a link to special object in `_collections` with `rel` base as a
#       key and `<xpath to owner node>.specialObjects.<collection rel>` as a
#       namespace.
#     + Set node to undefined.
# + Setup collections
#     + Detect that a set of the links are added to current node.
#     + Resolve collections namespace adding '/link' to current xpath.
#     + Retrieve search options for current xpath adding '/link' to it.
#     + Loop over related search options if existed and setup corresponding
#       collections.
#     + Resolve special objects namespace adding 'special_object/link' to
#       current xpath.
#     + Loop over related special objects adding them to corresponding
#       collections.
#     + Clean the applied `specialObjects` namespace.
# + Hydrate collections owner (right after collections setup).
#     + If `link` is array then remove undefined values from it.
#     + Delete link if it is an epty array or is undefined.
#     + Remove special objects element from node children.
#     + Use collection `rel` attribute as a collection name.
#     + Export collections to the current target (should be an API
#       node instance).
#     + Clean current namespace of the `_collections` property.
#
# ### Hydrate resource links
#
# + Value hydration
#     + Detect link to resource.
#     + Instantiate resource object.
#     + Get the element name from `xpath` (the last one).
#     + Save the node instance in `_resources` property with `xpath` base as a
#       namespace and element name as a key.
#     + Set resource link node value to undefined.
# + Resource links owner hydration.
#     + Detect that current node has a resource links.
#     + Retrive resource links related to `xpath`.
#     + Remove resource link child elements from target node.
#     + Export corresponding `_resourceLinks` namespace to current target.
#     + Remove related namespace from `_resourceLinks` property.
#
# ### Hydrate resources
#
# + Detect resources.
# + Create a resource object and set as a current target.
# + Proceed with API node hydration procedure.
#
# ### Hydrate actions
#
# + Hydrate action value
#     + Detect action.
#     + Instantiate actions object.
#     + Register action object in `_actions` with an action name as a key and
#       an owner node xpath as a namespace.
#     + Set raw node value to undefined.
# - Hydrate actions owner.
#     + Detect that current node has actions.
#     + Retrieve corresponding actions.
#     - Export related actions to current node.
#     - Remove `actions` child element from node value.
#     - Remove related namespace from `_actions` property.
#
# ### Hydrate properties of plain nodes
#
# + If node has an attributes then they should be merged to node hash.
# + For API nodes see "High level objects hydration" section.
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
    @_actions = {}
    @_collections = {}
    @_resourceLinks = {}

  #
  # Hydrates node value if necessary.
  #
  # This function called by parser every time it processes a node value.
  #
  # @param xpath [String] node's XPath
  # @param currentValue [undefined, mixed] current value of the node
  # @param newValue [mixed] node value
  #
  # @return [mixed] hydrated node value
  #
  hydrate: (xpath, currentValue, newValue) ->
    if @isApiNode xpath, newValue
      @hydrateApiNode xpath, newValue
    else
      @hydrateNode xpath, newValue

  #
  # Hydrates value for an API nodes.
  #
  # @param xpath [String] node's XPath
  # @param value [Object] node value
  #
  # @return [OVirtApiNode] hydrated API node
  #
  hydrateApiNode: (xpath, value) ->
    target = @_getTargetForNode xpath, value

    if @isCollectionsOwner xpath
      value = @hydrateCollections xpath, value, target

    if @isResourcesLinksOwner xpath
      value = @hydrateResourceLinks xpath, value, target

    @extractAttributes value, target
    @exportProperties value, target

    target

  #
  # Hydrates value of the "plain" node if necessary.
  #
  # @param xpath [String] node's XPath
  # @param value [mixed] node value
  #
  # @return [mixed] hydrated node value
  #
  hydrateNode: (xpath, value) ->
    if @isAction xpath, value
      @hydrateAction xpath, value
      undefined
    else if @isCollectionLink xpath, value
      @hydrateCollectionLink xpath, value
      undefined
    else if @isSearchOption value
      @hydrateSearchOption xpath, value
      undefined
    else if @isSpecialObject xpath, value
      @hydrateSpecialObject xpath, value
      undefined
    else if @isResourceLink value
      @hydrateResourceLink xpath, value
      undefined
    else
      @_mergeAttributes value
      value

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
    parentXpath = path.dirname xpath
    @registerIn @_collections,
      parentXpath, 'instances', attributes.rel,
      collection

    collection

  #
  # Hydrates collection search option.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [Object] hydrated search option
  #
  hydrateSearchOption: (xpath, node) ->
    searchOptions = @_getAttributes node
    name = path.dirname searchOptions.rel
    parentXpath = path.dirname xpath
    @registerIn @_collections,
      parentXpath, 'searchOptions', name,
      searchOptions

    searchOptions

  #
  # Hydrates collection special object.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [OVirtResource] hydrated special object
  #
  hydrateSpecialObject: (xpath, node) ->
    attributes = @_getAttributes node
    specialObject = new OVirtResource
    collection = path.dirname attributes.rel
    name = path.basename attributes.rel
    ownerXpath = path.dirname path.dirname xpath
    @registerIn @_collections,
      ownerXpath, 'specialObjects', collection, name,
      specialObject

    specialObject

  #
  # Hydrates a link to resource.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [OVirtResource] hydrated resource link
  #
  hydrateResourceLink: (xpath, node) ->
    resourceLink = new OVirtResource
    name = path.basename xpath
    parentXpath = path.dirname xpath
    @registerIn @_resourceLinks, parentXpath, name, resourceLink

    resourceLink

  #
  # Hydrates an action.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  #
  # @return [OVirtAction] hydrated action
  #
  hydrateAction: (xpath, node) ->
    attributes = @_getAttributes node
    action = new OVirtAction
    ownerXpath = path.dirname path.dirname xpath
    name = attributes.rel
    @registerIn @_actions, ownerXpath, name, action

    action

  #
  # Hydrates resource links.
  #
  # Loops over resource links assigned to xpath and exports them to the node or
  # hydrator target if this is a root node.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  # @param target [OVirtApiNode] node hydration target
  #
  # @return [Object] hydrated node
  #
  hydrateResourceLinks: (xpath, node, target) ->
    resourceLinks = @_getResourceLinksAtXPath xpath

    @_removeChildElements node, resourceLinks

    @exportResourceLinks resourceLinks, target

    try delete @_resourceLinks["#{xpath}"]

    node

  #
  # Hydrates collections.
  #
  # Loops over collections instances assigned to xpath and setup them with
  # corresponding search options and special objects.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node to be hydrated
  # @param target [OVirtApiNode] node hydration target
  #
  # @return [Object] hydrated node
  #
  hydrateCollections: (xpath, node, target) ->
    collections = @_getCollectionsAtXPath xpath
    searchOptions = @_getSearchOptionsAtXPath xpath
    specialObjects = @_getSpecialObjectsAtXPath xpath

    @_makeCollectionsSearchable collections, searchOptions
    @_cleanUpLinks node

    @_addSpecialObjects collections, specialObjects
    @_cleanUpSpecialObjects node

    @exportCollections collections, target

    try delete @_collections["#{xpath}"]

    node

  #
  # Removes empty values from links array and removes if it became empty.
  #
  # @param node [Object] node to clean up
  #
  # @private
  #
  _cleanUpLinks: (node) ->
    if _.isArray node[@LINK_PROPERTY]
      node[@LINK_PROPERTY] = _.compact node[@LINK_PROPERTY]
      delete node[@LINK_PROPERTY] if node[@LINK_PROPERTY].length is 0

  #
  # Removes empty values from links array and removes it became empty.
  #
  # @param node [Object] node to clean up
  #
  # @private
  #
  _cleanUpSpecialObjects: (node) ->
    delete node[@SPECIAL_OBJECTS]

  #
  # Removes specified child elements from the node.
  #
  # If object specified as a firs parameter its own property names will be
  # considered as a keys.
  #
  # @param node [Object] node to clean up
  # @param keys [Array, Object] keys to remove
  #
  # @return [Object] subject node
  #
  # @private
  #
  _removeChildElements: (node, keys) ->
    unless _.isArray keys
      keys = Object.getOwnPropertyNames keys

    for key in keys
      try delete node[key]

    node

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
  # Exports colections to target API node
  #
  # @param collections [Object] collections to export
  # @param target [OVirtApiNode] hydration target
  #
  exportCollections: (collections, target) ->
    target.collections = collections

  #
  # Exports resource links to target API node
  #
  # @param resourceLinks [Object] resource links to export
  # @param target [OVirtApiNode] hydration target
  #
  exportResourceLinks: (resourceLinks, target) ->
    target.resourceLinks = resourceLinks

  #
  # Exports node properties to target API node
  #
  # @param properties [Object] resource links to export
  # @param target [OVirtApiNode] hydration target
  #
  exportProperties: (properties, target) ->
    target.properties = properties

  #
  # Extract attributes from node and assign to hydration target.
  #
  # @param properties [Object] raw node value
  # @param target [OVirtApiNode] hydration target
  #
  extractAttributes: (node, target) ->
    attributes = @_getAttributes node
    target.attributes = attributes
    try delete node[@ATTRIBUTE_KEY]

  #
  # Tests whether specified subject is an API node.
  #
  # @param xpath [String] subject xpath
  # @param node [Object] subject xpath
  #
  # @return [Boolean] whether specified subject is a link
  #
  isApiNode: (xpath, node) ->
    @isCollectionsOwner(xpath) or
    @isResourcesLinksOwner(xpath) or
    @isResource node

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
  # Tests whether node under current xpath is a collections owner.
  #
  # @param xpath [String] xpath to node
  #
  # @return [Boolean]
  #
  isCollectionsOwner: (xpath) ->
    instances = @_getCollectionsAtXPath xpath
    return no unless _.isObject instances
    Object.getOwnPropertyNames(instances).length > 0

  #
  # Tests whether node under current xpath is a resource links owner.
  #
  # @param xpath [String] xpath to node
  #
  # @return [Boolean]
  #
  isResourcesLinksOwner: (xpath) ->
    links = @_getResourceLinksAtXPath xpath
    return no unless _.isObject links
    Object.getOwnPropertyNames(links).length > 0

  #
  # Tests whether node under current xpath is a actions owner.
  #
  # @param xpath [String] xpath to node
  #
  # @return [Boolean]
  #
  isActionsOwner: (xpath) ->
    actions = @_getActionsAtXPath xpath
    return no unless _.isObject actions
    Object.getOwnPropertyNames(actions).length > 0

  #
  # Tests whether specified subject is a link to collection.
  #
  # @param xpath [String] xpath to node
  # @param subject [Object] tested subject
  #
  # @return [Boolean] whether specified subject is a collection hash
  #
  isCollectionLink: (xpath, subject) ->
    return no if @_isActionXPath xpath
    return no unless @isLink subject
    return no if @isSearchOption subject
    attributes = @_getAttributes subject
    return no unless attributes
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
  # Tests whether specified subject is a link to search option.
  #
  # @param subject [Object] tested subject
  #
  # @return [Boolean] whether specified subject is a search option
  #
  isSearchOption: (subject) ->
    return no unless @isLink subject
    attributes = @_getAttributes subject
    return no unless attributes
    attributes.rel? and @_isSearchOptionRel attributes.rel

  #
  # Tests if value is a valid search option "rel" attribute.
  #
  # Rels with leading slashes treated as invalid.
  #
  # @param rel [String] link "rel" attribute
  #
  # @return [Boolean]
  #
  # @private
  #
  _isSearchOptionRel: (rel) ->
    /^\w+\/search$/.test rel

  #
  # Tests whether specified node is a special object.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node value
  #
  # @return [Boolean]
  #
  isSpecialObject: (xpath, node) ->
    return no unless @isResourceLink node
    @_isSpecialObjectXPath xpath

  #
  # Tests whether specified node is an action.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node value
  #
  # @return [Boolean]
  #
  isAction: (xpath, node) ->
    return no unless @isLink node
    @_isActionXPath xpath

  #
  # Returns hydration target for specified node.
  #
  # * It returns instance target for the root node.
  # * A resource object for nodes that could be considered as a resources.
  # * An API node for everything else.
  #
  # @param xpath [String] xpath to node
  # @param node [Object] node value (a hash)
  #
  # @return [OVirtApiNode] a target for node hydration
  #
  _getTargetForNode: (xpath, node) ->
    if @_isRootElememntXPath xpath
      @target
    else if @isResource node
      new OVirtResource
    else
      new OVirtApiNode

  #
  # Tests whether specified xpath leads to a special object.
  #
  # @param xpath [String] xpath to node
  #
  # @return [Boolean]
  #
  # @private
  #
  _isSpecialObjectXPath: (xpath) ->
    regExp = new RegExp "[\\w\\/]+\\/#{@SPECIAL_OBJECTS}\\/#{@LINK_PROPERTY}"
    regExp.test xpath

  #
  # Tests whether specified xpath leads to an action.
  #
  # @param xpath [String] xpath to node
  #
  # @return [Boolean]
  #
  # @private
  #
  _isActionXPath: (xpath) ->
    regExp = new RegExp "[\\w\\/]+\\/#{@ACTION_PROPERTY}\\/#{@LINK_PROPERTY}"
    regExp.test xpath

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
  # Returns collections instances for specified xpath.
  #
  # @param xpath [String]
  #
  # @return [Object] collections for xpath
  #
  # @private
  #
  _getCollectionsAtXPath: (xpath) ->
    collections = undefined
    try collections = @_collections[xpath].instances

    collections

  #
  # Returns collections search options for specified xpath.
  #
  # @param xpath [String]
  #
  # @return [Object] search options for xpath
  #
  # @private
  #
  _getSearchOptionsAtXPath: (xpath) ->
    searchOptions = undefined
    try searchOptions = @_collections[xpath].searchOptions

    searchOptions

  #
  # Returns collections special objects for specified xpath.
  #
  # @param xpath [String]
  #
  # @return [Object] special objects for xpath
  #
  # @private
  #
  _getSpecialObjectsAtXPath: (xpath) ->
    specialObjects = undefined
    try specialObjects = @_collections[xpath].specialObjects

    specialObjects

  #
  # Returns resource link objects for specified xpath.
  #
  # @param xpath [String]
  #
  # @return [Object] resource link objects for xpath
  #
  # @private
  #
  _getResourceLinksAtXPath: (xpath) ->
    specialObjects = undefined
    try specialObjects = @_resourceLinks[xpath]

    specialObjects

  #
  # Returns action objects for specified xpath.
  #
  # @param xpath [String]
  #
  # @return [Object] action objects for xpath
  #
  # @private
  #
  _getActionsAtXPath: (xpath) ->
    actions = undefined
    try actions = @_actions[xpath]

    actions

  #
  # Tests whether xpath points to root element.
  #
  # @param xpath [String] xpath to test
  #
  # @return [Boolean]
  #
  # @private
  #
  _isRootElememntXPath: (xpath) ->
    /^\/\w+$/.test xpath

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
  # Passes searchabilities to exact collections.
  #
  # @param collections [Object<OVirtCollection>] collections hash
  # @param searchabilities [Object] search options for selected collections
  #
  # @private
  #
  _makeCollectionsSearchable: (collections, searchabilities) ->
    for key of searchabilities
      collections[key].searchOptions =
        href: searchabilities[key].href

  #
  # Passes special objects to exact collections.
  #
  # @param collections [Object<OVirtCollection>] collections hash
  # @param specialObjects [Object<OVirtResource>] special objects
  #
  # @private
  #
  _addSpecialObjects: (collections, specialObjects) ->
    for collectionName, objects of specialObjects
      collection = collections[collectionName]
      for name, object of objects
        @_addSpecialObject collection, name, object


  #
  # Registers special object to specified collection.
  #
  # @param collections [OVirtCollection] collections hash
  # @param name [String] special object name
  # @param object [OVirtResource] special object as a link to resource
  #
  # @private
  #
  _addSpecialObject: (collection, name, object) ->
    collection[name] = object

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