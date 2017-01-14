path = require 'path'

getProjectDirectoryPath = (editor)->
  return '' if !editor

  editorPath = @editor.getPath()
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
    {data} = @processFrontMatter(@editor.getText())
    if !content.startsWith('---\n')
      return
    else
      end = content.indexOf('---\n', 4)
      content = content.slice(end+4)

    # pandoc

    # phantomjs

    # ebook

    # presentation, not supported yet

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