'use strict'
const Elm = require('./elm.js')
let container = document.getElementById('root') // grab the root div and
let embeddedElm = Elm.HackerDesktop.embed(container)   // start the elm app