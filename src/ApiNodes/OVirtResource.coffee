"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtResourse = class ApiNodes.OVirtResourse extends ApiNodes.OVirtApiNode
  #
  # @property [OVirtCollection]
  #   oVirt collection to which the resource is belongs to
  #
  collection: undefined


ApiNodes.OVirtApiNode.API_NODE_TYPES.resource = OVirtResourse

module.exports = OVirtResourse

