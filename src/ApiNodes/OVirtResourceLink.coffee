"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
  OVirtResource: require __dirname + '/OVirtResource'


OVirtResourseLink = class ApiNodes.OVirtResourseLink extends ApiNodes.OVirtApiNode
  #
  # Initiates instance and returns it.
  #
  # @return [OVirtApiNode] resolved resource instance
  #
  resolve: =>
    target = new ApiNodes.OVirtResource $owner: @
    name = @$attributes.name

    resource = @$connection.performRequest target, uri: @href

    if @$owner
      delete @$owner[name]
      @$owner[name] = resource

    resource


ApiNodes.OVirtApiNode.API_NODE_TYPES.resourceLink = OVirtResourseLink

module.exports = OVirtResourseLink

