"use strict"


OVirtCollection = require __dirname + '/OVirtCollection'
OVirtApiNode = require __dirname + '/OVirtApiNode'


class OVirtApi extends OVirtApiNode


OVirtApiNode.API_NODE_TYPES.api = OVirtApi

module.exports = OVirtApi