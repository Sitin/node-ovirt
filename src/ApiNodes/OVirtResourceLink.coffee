"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
  OVirtResource: require __dirname + '/OVirtResource'


OVirtResourseLink = class ApiNodes.OVirtResourseLink extends ApiNodes.OVirtApiNode
  #
  # Initiates instance and returns it.
  #
  # @return [OVirtApiNode] initiated instance
  #
  resolve: =>
    new ApiNodes.OVirtResource


ApiNodes.OVirtApiNode.API_NODE_TYPES.resourceLink = OVirtResourseLink

module.exports = OVirtResourseLink

