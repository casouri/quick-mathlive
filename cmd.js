#!/usr/bin/env node

const program = require('commander')
const net = require('net')
const process = require('process')
const child_process = require('child_process');
const electron = require('electron')

// Send text to electron mathlive process
function sendText(text) {
  const sock = new net.Socket()
  sock.setEncoding('utf-8')
  sock.connect(program.port || 14467, 'localhost')
  sock.on('data', (text) => {
    process.stdout.write(text)
  })
  // return when socket close
  sock.on('close', process.exit)
  sock.on('error', (err) => {
    if (err.code === 'ECONNREFUSED') {
      console.log('Connection refused, either server is not running or port is incorrect.')
    } else {
      console.error(err)
    }
    process.exit(1)
  })
  sock.write(text)
}

// main
program.version('0.0.1')

program
  .command('start')
  .description('Start background process')
  .action(() => {
    console.log(`Listening on port ${program.port || 14467}, Send ^C to exit.`)
    child_process.execFileSync(electron,
      [__dirname, program.port], {
        stdio: [process.stdin,
        process.stdout,
        process.stderr]
      })
  })

program
  .command('edit [latex]')
  .description('Edit Latex equations in mathlive')
  .action((latex) => {
    // pass latex and later return
    if (latex === 'QUIT') {
      latex = latex + ' '
    }
    sendText(latex)
  })

program
  .command('quit')
  .description('Quit background process')
  .action(() => {
    const sock = new net.Socket()
    sock.setEncoding('utf-8')
    sock.connect(program.port || 14467, 'localhost')
    sock.on('close', process.exit)
    sock.on('error', console.log)
    sock.write('QUIT')
    sock.end()
    process.exit()
  })

program.option('-p --port <port>', 'Port')

program.on('command:*', () => {
  console.error('Invalid command: %s\nSee --help for a list of available commands.', program.args.join(' '))
  process.exit(1)
})

program.parse(process.argv)
