'use strict'
let ipcR = require('electron').ipcRenderer;
const Elm = require('./elm.js')
//ipcR.sendSync('bootHND');
let container = document.getElementById('root') // grab the root div and
let embeddedElm = Elm.HackerDesktop.embed(container)   // start the elm app





//'use strict'
//let ipcR = require('electron').ipcRenderer;
//
//var embeddedElm=null
//function getHND() {
//  do {
//    ipcR.sendSync('bootHND')
//    console.log("foo")
//    setTimeout(function() {}, 100);
//  } while(embeddedElm==null);
//}
//getHND();
//const Elm = require('./elm.js')
//let container = document.getElementById('root') // grab the root div and
//let embeddedElm = Elm.HackerDesktop.embed(container)   // start the elm app