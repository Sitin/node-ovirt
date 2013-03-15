"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
Mixins = require __dirname + '/../Mixins/'
{Document} = require 'libxmljs'


OVirtAction = class ApiNodes.OVirtAction extends ApiNodes.OVirtApiNode
  # Included Mixins
  @include Mixins.Fiberable, ['perform']

  #
  # Performs current action in context of action owner.
  #
  perform: (callback) =>
    target = new ApiNodes.OVirtApiNode $owner: @$owner
    @$connection.performAction target, @, callback


ApiNodes.OVirtApiNode.API_NODE_TYPES.action = OVirtAction

module.exports = OVirtAction