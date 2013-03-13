"use strict"


ApiNodes =
  OVirtApiNode: require __dirname + '/OVirtApiNode'
  OVirtResource: require __dirname + '/OVirtResource'
Mixins = require __dirname + '/../Mixins/'


OVirtResourseLink = class ApiNodes.OVirtResourseLink extends ApiNodes.OVirtApiNode
  # Included Mixins
  @include Mixins.Fiberable, ['resolve']

  #
  # Initiates instance and returns it.
  #
  # @return [OVirtApiNode] initiated instance
  #
  resolve: (callback) =>
    target = new ApiNodes.OVirtResource $owner: @
    name = @$attributes.name

    @$connection.performRequest target, uri: @href, (error, resource) =>
      unless error?
        delete @$owner[name]
        @$owner[name] = resource

      callback error, resource if callback?


ApiNodes.OVirtApiNode.API_NODE_TYPES.resourceLink = OVirtResourseLink

module.exports = OVirtResourseLink

