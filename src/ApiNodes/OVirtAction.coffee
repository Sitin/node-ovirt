"use strict"

ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtAction = class ApiNodes.OVirtAction extends ApiNodes.OVirtApiNode
  #
  # Performs current action in context of action owner.
  #
  perform: (options) =>


ApiNodes.OVirtApiNode.API_NODE_TYPES.action = OVirtAction

module.exports = OVirtAction