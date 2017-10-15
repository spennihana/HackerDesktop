'use strict'
var path = require('path');
var fs = require('fs');
var dirPath = path.join(app.getPath("userData"), "hndlog")
if( !fs.existsSync(dirPath) ) {
  fs.mkdirSync(dirPath)
}
import { app, BrowserWindow, ipcMain } from 'electron';
import ElectronConsole from 'winston-electron';
import winston from 'winston';

var Log = new (winston.Logger)({
  transports: [
    new (winston.transports.File)({
      name: 'info-file',
      filename: path.join(app.getPath("userData"), "hndlog", "hndjs-info.log"),
      level: 'info'
    }),
    new (winston.transports.File)({
      name: 'error-file',
      filename: path.join(app.getPath("userData"), "hndlog", "hndjs-error.log"),
      level: 'error'
    })
  ]
});

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;
let hndProc = null;
var booted=false;

const startHNDesktopKt = () => {
  let java = path.join(__dirname, 'resources', 'jre', 'Contents', 'Home', 'bin', 'java')
  let jars = path.join(__dirname, 'resources', 'jars')
  let hndjar = path.join(jars, 'hnd.jar')
  let cp = hndjar + path.delimiter + path.join(jars, '*')
  let args = ['-cp', cp, 'com.hnd.HackerDesktopKt', app.getPath("userData")]

  Log.info("java: " + java)
  Log.info("args: " + args)
  hndProc = require('child_process').spawn(java, args)
  hndProc.stdout.on('data', (data) => {
    var d = data.toString();
    if( d.indexOf("booted")!=-1 ) {
      booted=true
      Log.info("hnd.jar successfully started.")
    }
  });

  hndProc.stderr.on('data', (data) => {
    Log.info("ERROR: " + data.toString())
  });
}

const killHackerDesktopProc = () => {
  Log.info("Shutting down HN Desktop...")
  if( hndProc!=null ) {
    hndProc.kill()
    hndProc = null
  }
}

ipcMain.on('boot', (event, arg) => {
  event.returnValue = booted;
})

app.on('will-quit', killHackerDesktopProc)
app.on('ready', startHNDesktopKt);

const createWindow = () => {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    titleBarStyle: 'hidden',
    webPreferences: {
      nativeWindowOpen: true
    }
  });

  mainWindow.webContents.on('new-window', (event, url, frameName, disposition, options, additionalFeatures) => {
    Object.assign(options, {
      width: 800,
      height: 600,
      titleBarStyle: 'show'
    })
  })

  // and load the index.html of the app.
  mainWindow.loadURL(`file://${__dirname}/index.html`);

  // Open the DevTools.
//  mainWindow.webContents.openDevTools();

  // Emitted when the window is closed.
  mainWindow.on('closed', () => {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null;
  }); 
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow);

// Quit when all windows are closed.
app.on('window-all-closed', () => {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.
