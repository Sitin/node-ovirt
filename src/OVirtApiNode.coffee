"use strict"


OVirtCollection = require __dirname + '/OVirtCollection'


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
class OVirtApiNode
  #
  # Each OVirtApiNode child adds themself to this hash.
  #
  @API_NODE_TYPES:
    {}

  #
  # @property [Object]
  #   collections that belongs to current API level
  #
  collections:
    {}

  #
  # @property [Object]
  #   properties that belongs to current API node
  #
  properties:
    {}

  constructor: (options) ->
    # We need only properties those are in the prototype
    for key of options
      @['_' + key] = options[key] if typeof @['_' + key] isnt 'undefined'


module.exports = OVirtApiNode

