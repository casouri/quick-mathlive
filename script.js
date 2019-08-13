const {ipcRenderer} = require('electron')
const MathLive = require('mathlive')

ipcRenderer.on('getLatex', () => {
  const latex = document.getElementById('latex').innerHTML
  console.log(`renderer: send latex ${latex}`)
  ipcRenderer.send('sendLatex', latex)
})

ipcRenderer.on('init', (_, arg) => {
  console.log(`renderer: recieved ${arg}`)
  if (arg) {
    document.getElementById('mathfield').innerHTML = arg
  }
  const mathfield = MathLive.makeMathField('mathfield', {
    smartMode: true,
    virtualKeyboardMode: 'manual',
    onContentDidChange: mathfield => {
      const latex = mathfield.$latex()
      document.getElementById('latex').innerHTML = escapeHtml(latex)
    }
  })
  // mathfield.$perform('selectAll')
  document.getElementsByTagName('textarea')[0].focus()
})

function escapeHtml (string) {
  return String(string).replace(/[&<>"'`=/\u200b]/g, function (s) {
    return {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;',
      '`': '&#x60;',
      '=': '&#x3D;',
      '\u200b': '&amp;#zws;'
    }[s] || s
  })
}
