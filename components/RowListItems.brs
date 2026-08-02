sub init()
    ' Initialize UI component references
    ' Инициализировать ссылки на компоненты интерфейса
    m.Poster = m.top.findNode("poster")
    m.Background = m.top.findNode("background")
    m.LoadingAnimation = m.top.findNode("LoadingAnimation")

    ' Set the default loading image
    ' Установить изображение загрузки по умолчанию
    m.Poster.uri = "pkg:/images/LODING.PNG" ' Loading placeholder image
                                            ' Изображение-заглушка во время загрузки
    m.currentUri = "pkg:/images/LODING.PNG"

    ' Register field observers
    ' Зарегистрировать наблюдателей за полями
    m.top.observeField("itemContent", "updateContent")
    m.top.observeField("height", "updateSize")
    m.top.observeField("width", "updateSize")
    m.Poster.observeField("loadStatus", "onPosterLoadStatus")
end sub

sub updateContent()
    ' Update the poster based on the current content
    ' Обновить постер в соответствии с текущим содержимым
    content = m.top.itemContent

    if content <> invalid
        if content.isLoading = true
            ' Display the loading placeholder and start the animation
            ' Отобразить заглушку загрузки и запустить анимацию
            m.Poster.uri = "pkg:/images/LODING.PNG"
            m.currentUri = "pkg:/images/LODING.PNG"
            m.LoadingAnimation.control = "start"
        else
            ' Stop the loading animation and load the actual poster
            ' Остановить анимацию загрузки и загрузить настоящий постер
            m.LoadingAnimation.control = "stop"
            m.Poster.opacity = 1.0

            ' Load a new poster only if its URL has changed
            ' Загружать новый постер только при изменении URL
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
    ' Resize the poster and background to match the component size
    ' Изменить размер постера и фона в соответствии с размером компонента
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
    ' Replace the poster with the fallback image if loading fails
    ' Заменить постер резервным изображением, если загрузка завершилась ошибкой
    if m.Poster.loadStatus = "failed" and m.currentUri <> "pkg:/images/SNIMAGEN.PNG"
        m.Poster.uri = "pkg:/images/SNIMAGEN.PNG" ' Fallback image
                                                  ' Резервное изображение
        m.currentUri = "pkg:/images/SNIMAGEN.PNG"
    end if
end sub

sub onLoadingChange()
    ' Update the poster when the loading state changes
    ' Обновить постер при изменении состояния загрузки
    if m.top.isLoading
        ' Display the loading placeholder and start the animation
        ' Отобразить заглушку загрузки и запустить анимацию
        ' TODO: Move loading placeholder handling to a separate function
        ' TODO: Вынести обработку заглушки загрузки в отдельную функцию
        m.Poster.uri = "pkg:/images/LODING.PNG"
        m.currentUri = "pkg:/images/LODING.PNG"
        m.LoadingAnimation.control = "start"
    else
        ' Stop the loading animation
        ' Остановить анимацию загрузки
        m.LoadingAnimation.control = "stop"
        m.Poster.opacity = 1.0
    end if
end sub