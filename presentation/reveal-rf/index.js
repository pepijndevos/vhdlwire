const { app, BrowserWindow, ipcMain } = require('electron')
const SerialPort = require('serialport')

if (process.argv.length < 3) {
  console.log('Error: Supply TTY path')
  process.exit(1)
}

const port = new SerialPort(
  process.argv[2],
  { baudRate: 1200 },
  function (err) {
    if (err) {
      console.log('Error: ', err.message)
      process.exit(1)
    }
  })

port.on('data', function (data) {
  console.log('Data:', data.toString())
})

function createWindow () {
  // Create the browser window.
  let win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true
    }
  })

  // and load the index.html of the app.
  win.loadFile('index.html')
}

app.on('ready', createWindow)

const width = 480/16
const height = 272/16

function formatSlide(text) {
  let buffer = "\f"
  text += "\n"
  const regexp = RegExp(`([^\n]{0,${width}})[ \n]`, 'g');
  const lines = [...text.matchAll(regexp)].map(function(n) { return n[1] });
  for (let r = 0; r < height; r++) {
    for (let c = 0; c < width; c++) {
      buffer += (lines[r] || [])[c] || " "
    }
  }
  return buffer
}

port.write("Initializing...\f")
port.write("Initializing...\f")
port.write("Initializing...\f")
port.write("Initializing...\f")
port.write("Initializing...\f")
port.write("Initializing...\f")

ipcMain.on('asynchronous-message', (event, arg) => {
  port.write(formatSlide(arg), function(err) {
    if (err) {
      return console.log('Error on write: ', err.message)
    }
    console.log(formatSlide(arg).length)
  })
})
