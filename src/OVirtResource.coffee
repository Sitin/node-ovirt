"use strict"


OVirtApiNode = require __dirname + '/OVirtApiNode'
OVirtCollection = require __dirname + '/OVirtCollection'


class OVirtResourse extends OVirtApiNode
  #
  # @property [OVirtCollection]
  #   oVirt collection to which the resource is belongs to
  #
  collection: undefined


OVirtApiNode.API_NODE_TYPES.resource = OVirtResourse

module.exports = OVirtResourse

