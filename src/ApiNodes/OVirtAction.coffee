"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
{Document} = require 'libxmljs'


OVirtAction = class ApiNodes.OVirtAction extends ApiNodes.OVirtApiNode
  #
  # Performs current action in context of action owner.
  #
  # @return [ApiNodes.OVirtApiNode]
  #
  perform: =>
    target = new ApiNodes.OVirtApiNode $owner: @$owner

    @$connection.performAction target, @


ApiNodes.OVirtApiNode.API_NODE_TYPES.action = OVirtAction

module.exports = OVirtAction