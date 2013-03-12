"use strict"


Mixins = {}

#
# Mixin for working with properties.
#
# @mixin
#
Mixins.ApiNodeTargetOwner =
  #
  # Sets current target.
  #
  # If target is a function then it considered as a constructor of the response
  # subject.
  #
  # If target is a string then it tries convert it to API node constructor
  # using {ApiNodes.OVirtApiNode API node's} types hash (API_NODE_TYPES).
  #
  # @param target [String, Function, ApiNodes.OVirtApiNode] response subject
  #
  # @throw [TypeError]
  #
  setTarget: (target) ->
    {OVirtApiNode} = require __dirname + '/../ApiNodes'

    if typeof target is 'string'
      target = OVirtApiNode.API_NODE_TYPES[target]

    if typeof target is 'function'
      target = new target connection: @connection

    if not (target instanceof OVirtApiNode)
      throw new
      TypeError "#{@constructor.name} requires OVirtApiNode as a target"

    @_target = target


module.exports = Mixins.ApiNodeTargetOwner