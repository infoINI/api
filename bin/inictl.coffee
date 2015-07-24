program = require 'commander'

logger = require '../lib/logger'
Dir = require '../lib/lh/dir'


index = (path, recursive, force) ->
  logger.info "starting to scan #{path}" +
              " #{"recursive" if recursive}, " +
              "#{'refreshing all' if all}"
  d = Dir.create(path)
  d.index(recursive)


program
  .option '-v, --verbose'
  .option '-d, --debug'
  .option '-q, --quiet'
  .option '-s, --silent'

program
  .command 'index <dir>'
  .description '(re)index a directory'
  .option '-r, --recursive', 'scan recursivly'
  .option '-a, --refresh-all', 'rescan files even if md5sum has not changed'
  .action (dir, options) ->
    logger.setLevel(program)
    logger.info 'index', dir
    process.exit()

program
  .command 'merge-pdf <files...>'
  .description 'merge images to one pdf using pdfjam'
  .action ->
    logger.setLevel(program)
    logger.info 'merge-pdf'

program
  .command 'list-uploads'
  .description 'list the uploads'
  .action (options) ->
    logger.setLevel(program)
    logger.info 'list-uploads'

program.parse process.argv
logger.setLevel(program)
program.help()

