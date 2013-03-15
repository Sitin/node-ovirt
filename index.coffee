"use strict"


if module.parent
  module.exports = require __dirname + '/lib/'
else
  require './test/module.func'