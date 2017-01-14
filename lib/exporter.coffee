path = require 'path'
{processFrontMatter} = require './md'

pandocConvert = require './pandoc-convert'

getProjectDirectoryPath = (editor)->
  return '' if !editor

  editorPath = editor.getPath()
  projectDirectories = atom.project.rootDirectories
  for projectDirectory in projectDirectories
    if (projectDirectory.contains(editorPath)) # editor belongs to this project
      return projectDirectory.getPath()

  return ''

exportToDisk = ()->
  editor = atom.workspace.getActiveTextEditor()
  fileExtension = path.extname(editor.getPath())
  fileExtensions = atom.config.get('markdown-preview-enhanced.fileExtension').split(',').map((x)->x.trim())
  return if not (fileExtension in fileExtensions)
  console.log 'export to disk'

  filePath = editor.getPath()
  rootDirectoryPath = editor.getDirectoryPath()
  projectDirectoryPath = getProjectDirectoryPath()

  return exportToDiskForFile {filePath, rootDirectoryPath, projectDirectoryPath}

exportToDiskForFile = ({filePath, rootDirectoryPath, projectDirectoryPath})->
  content = fs.readFile filePath, {encoding: 'utf-8'}, (err, content)->
    return if err
    content = content.trim()
    {data} = processFrontMatter(content)
    data = data or {}
    if !content.startsWith('---\n')
      return
    else
      end = content.indexOf('---\n', 4)
      content = content.slice(end+4)

    # pandoc
    # check docs/advanced-export.md
    if data.output
      pandocConvert content, {rootDirectoryPath, projectDirectoryPath, sourceFilePath: filePath}, data, (err, outputFilePath)->
        if err
          return atom.notifications.addError 'pandoc error', detail: err
        atom.notifications.addInfo "File #{path.basename(outputFilePath)} was created", detail: "path: #{outputFilePath}"

    # html
    ###
    html:
      path: output.md
      cdn: true
    ###
    

    # phantomjs
    ###
    phantomjs:
      path
      format
      orientation
      margin
      header
      footer
    ###


    # ebook

    # presentation, only .html export is supported for now

    # markdown
    # TODO: append front matter

exportAllToDisk = ()->
  # TODO: to be implemented
  console.log 'export all to disk'
  true

module.exports = {
  exportToDisk,
  exportAllToDisk
}