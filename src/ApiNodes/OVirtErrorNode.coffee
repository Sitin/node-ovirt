"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtErrorNode = class ApiNodes.OVirtErrorNode extends ApiNodes.OVirtApiNode
  # Mark all instances as errors
  isError: yes


ApiNodes.OVirtApiNode.API_NODE_TYPES.error = OVirtErrorNode


module.exports = OVirtErrorNode