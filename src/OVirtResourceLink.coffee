"use strict"


OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtResource = require __dirname + '/OVirtResource'


class OVirtResourseLink extends OVirtApiNode
  #
  # Initiates instance and returns it.
  #
  # @return [OVirtApiNode] initiated instance
  #
  resolve: =>
    new OVirtResource


OVirtApiNode.API_NODE_TYPES.resourceLink = OVirtResourseLink

module.exports = OVirtResourseLink

