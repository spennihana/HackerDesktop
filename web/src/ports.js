'use strict'
const Elm = require('./elm.js')
let container = document.getElementById('root') // grab the root div and

let ipcR = require('electron').ipcRenderer;
let embeddedElm = null
var booted=false;
function boot() {
  while( !booted ) {
    booted = ipcR.sendSync('boot')
    setTimeout(function() {}, 100);
  }
  embeddedElm = Elm.HackerDesktop.embed(container)   // start the elm app
}

boot();