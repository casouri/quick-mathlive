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
  sock.on('close', () => {
    process.exit()
  })
  sock.write(text)
}

// main
program.version('0.0.1')

program
  .command('start')
  .description('Start background process')
  .action(() => {
    child_process.execFileSync(electron, [__dirname])
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
    sock.write('QUIT')
    sock.end()
  })

program.option('-p --port <port>', 'Port')

program.parse(process.argv)
