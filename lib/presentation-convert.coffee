###
resolveFilePath
@param {String} filePath
@param {Object}
  @param {String} rootDirectoryPath
  @param {String} projectDirectory
@param {Boolean} relative
###
resolveFilePath: (filePath, {rootDirectoryPath, projectDirectoryPath} relative=false)->
  if filePath.startsWith('./') or filePath.startsWith('/')
    if relative
      if filePath[0] == '.'
        return filePath
      else
        return path.relative(rootDirectoryPath, path.resolve(projectDirectoryPath, '.'+filePath))
    else
      if filePath[0] == '.'
        return 'file:///'+path.resolve(rootDirectoryPath, filePath)
      else
        return 'file:///'+path.resolve(projectDirectoryPath, '.'+filePath)
  else
    return filePath

###
presentationConvert:
@param {String} html: html string, parsed by parseMD function in md.coffee
@param {Object}
  @param {String} rootDirectoryPath
  @param {String} projectDirectory
  @param {Boolean} isSavingToHTML
@param {Object} slideConfigs: got from parseMD function in md.coffee
###
presentationConvert = (html, {rootDirectoryPath, projectDirectoryPath, isSavingToHTML}, slideConfigs)->
  slides = html.split '<div class="new-slide"></div>'
  slides = slides.slice(1)
  output = ''

  parseAttrString = (slideConfig)=>
    attrString = ''
    if slideConfig['data-background-image']
      attrString += " data-background-image='#{resolveFilePath(slideConfig['data-background-image'], {rootDirectoryPath, projectDirectoryPath}, isSavingToHTML)}'"

    if slideConfig['data-background-size']
      attrString += " data-background-size='#{slideConfig['data-background-size']}'"

    if slideConfig['data-background-position']
      attrString += " data-background-position='#{slideConfig['data-background-position']}'"

    if slideConfig['data-background-repeat']
      attrString += " data-background-repeat='#{slideConfig['data-background-repeat']}'"

    if slideConfig['data-background-color']
      attrString += " data-background-color='#{slideConfig['data-background-color']}'"

    if slideConfig['data-notes']
      attrString += " data-notes='#{slideConfig['data-notes']}'"

    if slideConfig['data-background-video']
      attrString += " data-background-video='#{resolveFilePath(slideConfig['data-background-video'], {rootDirectoryPath, projectDirectoryPath}, isSavingToHTML)}'"

    if slideConfig['data-background-video-loop']
      attrString += " data-background-video-loop"

    if slideConfig['data-background-video-muted']
      attrString += " data-background-video-muted"

    if slideConfig['data-transition']
      attrString += " data-transition='#{slideConfig['data-transition']}'"

    if slideConfig['data-background-iframe']
      attrString += " data-background-iframe='#{resolveFilePath(slideConfig['data-background-iframe'], {rootDirectoryPath, projectDirectoryPath}, isSavingToHTML)}'"
    attrString

  i = 0
  while i < slides.length
    slide = slides[i]
    slideConfig = slideConfigs[i]
    attrString = parseAttrString(slideConfig)

    if !slideConfig['vertical']
      if i > 0 and slideConfigs[i-1]['vertical'] # end of vertical slides
        output += '</section>'
      output += "<section #{attrString}>#{slide}</section>"
      i += 1
    else # vertical
      if i > 0
        if !slideConfigs[i-1]['vertical'] # start of vertical slides
          output += "<section><section #{attrString}>#{slide}</section>"
        else
          output += "<section #{attrString}>#{slide}</section>"
      else
        output += "<section><section #{attrString}>#{slide}</section>"

      i += 1

  if i > 0 and slideConfigs[i-1]['vertical'] # end of vertical slides
    output += "</section>"

  """
  <div class="reveal">
    <div class="slides">
      #{output}
    </div>
  </div>
  """

module.exports = presentationConvert