"use strict"


{CoffeeMix} = require 'coffee-mix'
_ = require 'lodash'
ApiNodes = {}
Mixins = require __dirname + '/../Mixins/'


#
# API node level
# ---------------
#
# 26. Collections and resources (both regular and the root one) are considered
#     as API nodes.
# 27. API nodes doesn't call API during construction but could be refreshed.
# 28. Regular refresh doesn't affect child nodes.
# 29. Deep refresh implementation could be considered in future releases.
# 30. Every node knows it's base URI (an URI of the parent node).
# 31. Every node knows how to represent itself as an API URI element.
# 32. So, a node knows it's own dedicated API URI.
# 33. Every node passes it's dedicated URI to the children as their base URI
#     during their construction.
# 34. We do not consider base URI recalculation in current release.
# 35. Some API nodes properties (both in collections and resources) could be
#     a links to other resources. And that means that we probably should
#     instantiate their collections (and maybe the owning resources of their
#     collections and so on) once we retrieve them.
# 36. To perform API call a node requests oVirt connection to create an API
#     request object, configurates it and executes.
#
# @include Mixins.PropertyDistributor
#
OVirtApiNode = class ApiNodes.OVirtApiNode extends CoffeeMix
  # Included mixins
  @include Mixins.PropertyDistributor

  # CoffeeMix property helpers
  get = => @get arguments...
  set = => @set arguments...

  #
  # Each OVirtApiNode child adds themself to this hash.
  #
  @API_NODE_TYPES:
    {}

  #
  # List of the system properties
  #
  @RESTRICTED_KEYS: [
    '$actions'
    '$attributes'
    '$collections'
    '$connection'
    '$owner'
    '$properties'
    '$resourceLinks'
  ]

  #
  # @property [Object<ApiNodes.OVirtAction>]
  #   actions that belongs to current API node
  #
  get $actions: -> @_$actions
  #
  # Sets API node actions.
  #
  # @param actions [Object<ApiNodes.OVirtAction>]
  #
  setActions: (actions) ->
    @populateActions actions
    @_$actions = actions

  #
  # @property [Object]
  #   attributes that belongs to current API node
  #
  get $attributes: -> @_$attributes
  #
  # Sets API node attributes.
  #
  # @param attributes [Object]
  #
  setAttributes: (attributes) ->
    @populateProperties attributes, @_$attributes
    @_$attributes = attributes

  #
  # @property [Object<ApiNodes.OVirtCollection>]
  #   collections that belongs to current API level
  #
  get $collections: -> @_$collections
  #
  # Sets API node collections.
  #
  # @param collections [Object<ApiNodes.OVirtCollection>]
  #
  setCollections: (collections) ->
    @populateProperties collections, @_$collections
    @_$collections = collections

  #
  # @property [OVirtConnection]
  #   current connection instance
  #
  get $connection: -> do @getConnection
  set $connection: (connection) -> @_$connection = connection
  #
  # Gets API node connection.
  #
  # @return [OVirtConnection] current connection
  #
  getConnection: ->
    if not @_$connection? and @$owner?
      @$connection = @$owner.$connection

    @_$connection

  #
  # @property [ApiNodes.OVirtApiNode] current node owner
  #
  get $owner: -> @_$owner
  set $owner: (owner) -> @_$owner = owner

  #
  # @property [Object]
  #   properties that belongs to current API node
  #
  get $properties: -> @_$properties
  #
  # Sets API node properties.
  #
  # @param properties [Object]
  #
  setProperties: (properties) ->
    @populateProperties properties, @_$properties
    @_$properties = properties

  #
  # @property [Object<ApiNodes.OVirtResourceLinks>]
  #   resource links that belongs to current API node
  #
  get $resourceLinks: -> @_$resourceLinks
  #
  # Sets API node resource links.
  #
  # @param resourceLinks [Object]
  #
  setResourceLinks: (resourceLinks) ->
    @populateResourceLinks resourceLinks
    @_$resourceLinks = resourceLinks

  constructor: (options = {}) ->
    # Set instance defaults
    @_$actions = {}
    @_$attributes = {}
    @_$collections = {}
    @_$connection = null
    @_$owner = null
    @_$properties = {}
    @_$resourceLinks = {}

    # Setup properties
    @setupExistedProperties options

  #
  # Populates passed properties over API node instance.
  #
  # Deletes old properties if specified.
  #
  # @param properties [Object] property hash to populate
  # @param oldProperties [Object] recent properties to delete
  #
  populateProperties: (properties = {}, oldProperties = {}) ->
    delete @[key] for key of oldProperties
    return unless typeof properties is 'object'

    for key, value of properties when key not in OVirtApiNode.RESTRICTED_KEYS
      @consumeProperty value
      @[key] = value

  #
  # Populates actions over API node instance.
  #
  # Adds methods that perform corresponding actions and unpopulates current
  # actions.
  #
  # @param actions [Object<[ApiNodes.OVirtAction>] actions hash to populate
  #
  populateActions: (actions = {})->
    delete @[key] for key of @_actions
    return unless typeof actions is 'object'

    for key, value of actions when key not in OVirtApiNode.RESTRICTED_KEYS
      @addAction key, value

  #
  # Populates resource links over API node instance.
  #
  # Adds properties that lazy loads resources from specified resource links and
  # unpopulates current resource links.
  #
  # @param resourceLinks [Object<[ApiNodes.OVirtResourceLink>] actions hash to
  #   populate
  #
  populateResourceLinks: (resourceLinks = {}) ->
    delete @[key] for key of @_resourceLinks
    return unless typeof resourceLinks is 'object'

    for key, value of resourceLinks when key not in OVirtApiNode.RESTRICTED_KEYS
      @addResourceLink key, value

  #
  # Adds action to API node.
  #
  # Binds action to current node and creates instance method with specified
  # name that performs the action.
  #
  # @param name [String] action name
  # @param action [ApiNodes.OVirtAction] action to add
  #
  addAction: (name, action) ->
    action.$owner = @
    @[name] = action.perform

  #
  # Adds resource link to API node.
  #
  # Adds property to current node that lazy loads resource from the resource
  # link.
  #
  # @param name [String] resource link name
  # @param action [ApiNodes.OVirtResourceLink] resource link to add
  #
  addResourceLink: (name, resourceLink) ->
    resourceLink.$owner = @
    resourceLink.name = name
    @.__defineGetter__ name, resourceLink.resolve

  #
  # Sets current node as a property owner if property is an API node.
  #
  # If property value is an array then method will try to consume it contents.
  #
  # @param value [mixed] property value
  #
  # @return [mixed] property value
  #
  consumeProperty: (value) ->
    if _.isArray value
      @consumeProperty entry for entry in value
    else
      value.$owner = @ if value instanceof OVirtApiNode

    value


OVirtApiNode.API_NODE_TYPES.node = OVirtApiNode

module.exports = OVirtApiNode

