const { app, BrowserWindow, ipcMain } = require('electron')
const net = require('net');

function createWindow(text, socket) {
  // Create the browser window.
  let win = new BrowserWindow({
    width: 400,
    height: 300,
    webPreferences: {
      nodeIntegration: true
    }
  })

  // don’t quit when all windows closed
  app.on('window-all-closed', e => e.preventDefault())

  // and load the index.html of the app.
  win.loadFile('index.html')

  // and init
  win.webContents.on('did-finish-load', () => {
    win.webContents.send('init', text)
    win.webContents.focus()
  })

  // return latex when close window
  win.on('close', event => {
    console.log('main: closing, ask for latex')
    win.webContents.send('getLatex')
    // don’t close before got latex
    event.preventDefault()
  })
  // received latex
  ipcMain.once('sendLatex', (_, arg) => {
    console.log(`main: got latex ${arg}`)
    // send latex and close
    socket.write(arg, () => {
      console.log('server: finished writing, send FIN')
      socket.end()
    })
  })

  socket.on('close', () => {
    console.log('server: socket closed')
    win.destroy() // close window, skip on-close check
  })
}

function startServer() {
  const server = net.createServer((socket) => {
    socket.setEncoding('utf-8')
    socket.on('error', console.error)
    socket.once('data', (data) => {
      if (data === 'QUIT') {
        console.log('server: receive QUIT')
        server.close(app.quit)
      } else {
        createWindow(data, socket)
      }
    })
  })
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log('Default address 14467 is in use. Try another one with -p flag.')
    } else {
      console.error(err)
    }
    process.exit()
  })
    server.listen(Number(process.argv[2]) || 14467, 'localhost')
}

app.on('ready', startServer)
