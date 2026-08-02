sub init()
    m.Poster = m.top.findNode("poster")
    m.Background = m.top.findNode("background")
    m.LoadingAnimation = m.top.findNode("LoadingAnimation")
    m.Poster.uri = "pkg:/images/LODING.PNG" ' Imagen mientras carga
    m.currentUri = "pkg:/images/LODING.PNG"
    m.top.observeField("itemContent", "updateContent")
    m.top.observeField("height", "updateSize")
    m.top.observeField("width", "updateSize")
    m.Poster.observeField("loadStatus", "onPosterLoadStatus")
end sub

sub updateContent()
    content = m.top.itemContent
    if content <> invalid
        if content.isLoading = true
            ' Modo cargando: usar la imagen de placeholder y activar la animación
            m.Poster.uri = "pkg:/images/LODING.PNG"
            m.currentUri = "pkg:/images/LODING.PNG"
            m.LoadingAnimation.control = "start"
        else
            ' Contenido real: detener la animación y cargar la imagen
            m.LoadingAnimation.control = "stop"
            m.Poster.opacity = 1.0
            if content.HDPosterUrl <> invalid and content.HDPosterUrl <> "" and content.HDPosterUrl <> m.currentUri
                m.Poster.loadWidth = 240
                m.Poster.loadHeight = 135
                m.Poster.uri = content.HDPosterUrl
                m.currentUri = content.HDPosterUrl
            end if
        end if
    end if
end sub

sub updateSize()
    w = m.top.width
    h = m.top.height
    if w > 0 and h > 0
        m.Poster.width = w
        m.Poster.height = h
        m.Background.width = w
        m.Background.height = h
    end if
end sub

sub onPosterLoadStatus()
    if m.Poster.loadStatus = "failed" and m.currentUri <> "pkg:/images/SNIMAGEN.PNG"
        m.Poster.uri = "pkg:/images/SNIMAGEN.PNG" ' Imagen si falla
        m.currentUri = "pkg:/images/SNIMAGEN.PNG"
    end if
end sub

sub onLoadingChange()
    if m.top.isLoading
        ' Modo cargando: usar la imagen de placeholder y activar la animación
        m.Poster.uri = "pkg:/images/LODING.PNG"
        m.currentUri = "pkg:/images/LODING.PNG"
        m.LoadingAnimation.control = "start"
    else
        ' Detener la animación si ya no está en modo cargando
        m.LoadingAnimation.control = "stop"
        m.Poster.opacity = 1.0
    end if
end sub
