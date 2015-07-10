commander = require 'commander'

commander
  .command 'index <dir>'
  .description '(re)index a file'
    .option '-r, --recursive', 'scan recursivly'
    .option '-n, --no-report', 'do not send email reports'
commander
  .command 'list-uploads'
  .description 'list the uploads'

commander.parse process.argv
