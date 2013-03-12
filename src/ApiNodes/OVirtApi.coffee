"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'


OVirtApi = class ApiNodes.OVirtApi extends ApiNodes.OVirtApiNode


ApiNodes.OVirtApiNode.API_NODE_TYPES.api = OVirtApi

module.exports = OVirtApi