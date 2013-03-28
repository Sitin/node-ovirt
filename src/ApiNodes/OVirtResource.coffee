"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtResourse = class ApiNodes.OVirtResourse extends ApiNodes.OVirtApiNode
  #
  # Removes the resource.
  #
  # @return [Boolean]
  #
  remove: ->
    target = new ApiNodes.OVirtApiNode
    @$connection.remove target, @href
    @clear()

    yes


ApiNodes.OVirtApiNode.API_NODE_TYPES.resource = OVirtResourse

module.exports = OVirtResourse

