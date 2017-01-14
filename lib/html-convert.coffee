{parseMD} = require './md'
{singletonHook} = require './hook'
presentationConvert = require './presentation-convert'
processGraphs = require './process-graphs'

formatStringBeforeParsing: (str)->
  singletonHook.chain('on-will-parse-markdown', str)

formatStringAfterParsing: (str)->
  singletonHook.chain('on-did-parse-markdown', str)

###
@param {String} text: markdown string
@param {Object}
  @param {String} rootDirectoryPath
  @param {String} projectDirectory
  @param {String} title
  @param {Boolean} isForPrint
  @param {Boolean} offline
  @param {Boolean} isSavingToHTML
  @param {Boolean|String} phantomjsType: pdf | png | jpeg | false
  @param {Object} markdownPreview: MarkdownPreviewEnhancedView, optional
###
getHTMLContent = (text, {rootDirectoryPath, projectDirectoryPath, title, isForPrint, offline, isSavingToHTML, phantomjsType, markdownPreview})->
  title ?= "unamed"
  isForPrint ?= false
  offline ?= false
  isSavingToHTML ?= false
  phantomjsType ?= false # pdf | png | jpeg | false
  markdownPreview ?= null

  if markdownPreview
    return helper(text)
  else
    processGraphs text, {rootDirectoryPath, projectDirectoryPath, imageDirectoryPath: rootDirectoryPath}, (text, imagePaths=[])->
      return helper(text)

  helper = (text)->
    ## TODO: remove atom.config.get ?
    useGitHubStyle = atom.config.get('markdown-preview-enhanced.useGitHubStyle')
    useGitHubSyntaxTheme = atom.config.get('markdown-preview-enhanced.useGitHubSyntaxTheme')
    mathRenderingOption = atom.config.get('markdown-preview-enhanced.mathRenderingOption')

    res = parseMD(formatStringBeforeParsing(text), {isSavingToHTML, rootDirectoryPath, projectDirectoryPath, markdownPreview, hideFrontMatter: true})
    htmlContent = formatStringAfterParsing(res.html)
    slideConfigs = res.slideConfigs
    yamlConfig = res.yamlConfig || {}

    # as for example black color background doesn't produce nice pdf
    # therefore, I decide to print only github style...
    if isForPrint
      useGitHubStyle = atom.config.get('markdown-preview-enhanced.pdfUseGithub')

    if mathRenderingOption == 'KaTeX'
      if offline
        mathStyle = "<link rel=\"stylesheet\"
              href=\"file:///#{path.resolve(__dirname, '../node_modules/katex/dist/katex.min.css')}\">"
      else
        mathStyle = "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.7.0/katex.min.css\">"
    else if mathRenderingOption == 'MathJax'
      inline = atom.config.get('markdown-preview-enhanced.indicatorForMathRenderingInline')
      block = atom.config.get('markdown-preview-enhanced.indicatorForMathRenderingBlock')
      if offline
        mathStyle = "
        <script type=\"text/x-mathjax-config\">
          MathJax.Hub.Config({
            messageStyle: 'none',
            tex2jax: {inlineMath: #{inline},
                      displayMath: #{block},
                      processEscapes: true}
          });
        </script>
        <script type=\"text/javascript\" async src=\"file://#{path.resolve(__dirname, '../dependencies/mathjax/MathJax.js?config=TeX-AMS_CHTML')}\"></script>
        "
      else
        # inlineMath: [ ['$','$'], ["\\(","\\)"] ],
        # displayMath: [ ['$$','$$'], ["\\[","\\]"] ]
        mathStyle = "
        <script type=\"text/x-mathjax-config\">
          MathJax.Hub.Config({
            messageStyle: 'none',
            tex2jax: {inlineMath: #{inline},
                      displayMath: #{block},
                      processEscapes: true}
          });
        </script>
        <script type=\"text/javascript\" async src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML\"></script>
        "
    else
      mathStyle = ''

    # presentation
    if slideConfigs.length
      htmlContent = presentationConvert(htmlContent, {rootDirectoryPath, projectDirectoryPath, isSavingToHTML}, slideConfigs)
      if offline
        presentationScript = "
        <script src='file:///#{path.resolve(__dirname, '../dependencies/reveal/lib/js/head.min.js')}'></script>
        <script src='file:///#{path.resolve(__dirname, '../dependencies/reveal/js/reveal.js')}'></script>"
      else
        presentationScript = "
        <script src='https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.4.0/lib/js/head.min.js'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.4.0/js/reveal.min.js'></script>"

      presentationConfig = yamlConfig['presentation'] or {}
      dependencies = presentationConfig.dependencies or []
      if presentationConfig.enableSpeakerNotes
        if offline
          dependencies.push {src: path.resolve(__dirname, '../dependencies/reveal/plugin/notes/notes.js'), async: true}
        else
          dependencies.push {src: 'revealjs_deps/notes.js', async: true} # TODO: copy notes.js file to corresponding folder
      presentationConfig.dependencies = dependencies

      #       <link rel=\"stylesheet\" href='file:///#{path.resolve(__dirname, '../dependencies/reveal/reveal.css')}'>
      presentationStyle = """
      <style>
      #{fs.readFileSync(path.resolve(__dirname, '../dependencies/reveal/reveal.css'))}

      #{if isForPrint then fs.readFileSync(path.resolve(__dirname, '../dependencies/reveal/pdf.css')) else ''}
      </style>
      """

      presentationInitScript = """
      <script>
        Reveal.initialize(#{JSON.stringify(Object.assign({margin: 0.1}, presentationConfig))})
      </script>
      """

      presentationMode = true

    else
      presentationScript = ''
      presentationStyle = ''
      presentationInitScript = ''
      presentationMode = false

    # phantomjs
    phantomjsClass = ""
    if phantomjsType
      if phantomjsType == '.pdf'
        phantomjsClass = 'phantomjs-pdf'
      else if phantomjsType == '.png' or phantomjsType == '.jpeg'
        phantomjsClass = 'phantomjs-image'

    htmlContent = "
  <!DOCTYPE html>
  <html>
    <head>
      <title>#{title}</title>
      <meta charset=\"utf-8\">
      <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">

      #{presentationStyle}

      <style>
      #{getMarkdownPreviewCSS()}
      </style>

      #{mathStyle}

      #{presentationScript}
    </head>
    <body class=\"markdown-preview-enhanced #{phantomjsClass}\"
        #{if useGitHubStyle then 'data-use-github-style' else ''}
        #{if useGitHubSyntaxTheme then 'data-use-github-syntax-theme' else ''}
        #{if presentationMode then 'data-presentation-mode' else ''}>

    #{htmlContent}

    </body>
    #{presentationInitScript}
  </html>
    "

htmlConvert = ()->
  true

module.exports = {htmlConvert, getHTMLContent}