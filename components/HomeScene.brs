sub init()
    ' Simplify the node structure
    ' Упростить структуру узлов
    m.nodes = {
        Video: m.top.findNode("Video"),
        PreviewPoster: m.top.findNode("PreviewPoster"),
        FadeInPreview: m.top.findNode("FadeInPreview"),
        FadeOutPreview: m.top.findNode("FadeOutPreview"),
        RowList: m.top.findNode("RowList"),
        Labels: {
            Category: m.top.findNode("CategoryLabel"),
            Category2: m.top.findNode("CategoryLabel2"),
            ChannelCount: m.top.findNode("ChannelCountLabel"),
            Info: m.top.findNode("InfoLabel")
        },
        InfoBar: m.top.findNode("InfoBar"),
        Timer: m.top.findNode("ChannelLoadedTimer"),
        Scrolls: {
            Up: m.top.findNode("ScrollCategoryLabelUp"),
            Down: m.top.findNode("ScrollCategoryLabelDown"),
            Up2: m.top.findNode("ScrollCategoryLabel2Up"),
            Down2: m.top.findNode("ScrollCategoryLabel2Down")
        },
        Menu: m.top.findNode("SideMenu"),
        MenuItems: m.top.findNode("MenuItems"),
        MenuLabels: {
            Home: m.top.findNode("MenuLabel0"),
            Search: m.top.findNode("MenuLabel1"),
            Playlist: m.top.findNode("MenuLabel2"),
            Language: m.top.findNode("MenuLabel3")
        },
        ExpandMenu: m.top.findNode("ExpandMenu"),
        CollapseMenu: m.top.findNode("CollapseMenu"),
        LoadingAnim1: m.top.findNode("LoadingAnimation1"),
        LoadingAnim2: m.top.findNode("LoadingAnimation2")
    }

    ' Load the saved interface language
    ' Загрузить сохранённый язык интерфейса
    m.languageCode = loadSavedLanguage()
    m.locale = loadLanguage(m.languageCode)
    applyLanguage()

    ' Configure the Video node for faster startup
    ' Настроить узел Video для более быстрого запуска
    m.nodes.Video.enableUI = false
    m.nodes.Video.loop = true
    m.nodes.Video.enableTrickPlay = true

    ' Set the default playlist URL and load the most recent URLs from the registry
    ' Задать URL плейлиста по умолчанию и загрузить последние URL из реестра
    m.originalUrl = "https://raw.githubusercontent.com/smolnp/IPTVru/refs/heads/gh-pages/IPTVstable.m3u8" ' Default playlist URL
    m.global.addFields({lastUrl: m.originalUrl})
    m.state = {isFullScreen: false, lastRow: 0, menuItem: 0, menuFocused: false}
    m.recentUrls = loadRecentUrls() ' Load recent playlist URLs
    if m.recentUrls.count() > 0 then
        m.global.lastUrl = m.recentUrls[0] ' Use the most recently saved URL as the default
    end if
    
    ' Load saved playlists from the registry
    ' Загрузить сохранённые плейлисты из реестра
    m.playlists = loadPlaylists()    

    ' Load the saved playlist loading timeout
    ' Загрузить сохранённый тайм-аут загрузки плейлиста
    m.playlistTimeoutSeconds = loadPlaylistTimeout()
        

    ' Initialize placeholder content
    ' Инициализировать содержимое-заглушку
    m.content = createObject("roSGNode", "ContentNode")
    for i = 0 to 1
        cat = createObject("roSGNode", "ContentNode")
        cat.title = m.locale.Loading
        for j = 0 to 19
            item = createObject("roSGNode", "ContentNode")
            item.addField("isLoading", "boolean", true)
            item.isLoading = true
            cat.appendChild(item)
        end for
        m.content.appendChild(cat)
    end for
    
    ' Configure the initial interface
    ' Настроить начальный интерфейс
    m.nodes.RowList.content = m.content
    m.nodes.RowList.setFocus(true)
    m.nodes.Labels.Category.text = m.locale.Loading
    m.nodes.Labels.Category2.text = m.locale.Loading
    m.nodes.LoadingAnim1.control = "start"
    m.nodes.LoadingAnim2.control = "start"
    
    ' Configure the loading progress timer
    ' Настроить таймер прогресса загрузки
    m.loadingTimer = m.top.findNode("LoadingProgressTimer")
    m.loadingTimer.observeField("fire", "updateLoadingProgress")
    m.loadingProgress = 0
    m.isLoadingList = true
    m.loadingTimer.control = "start"
    
    ' Create a timer to reset the error state
    ' Создать таймер для сброса состояния ошибки
    m.errorResetTimer = createObject("roSGNode", "Timer")
    m.errorResetTimer.id = "ErrorResetTimer"
    m.errorResetTimer.duration = 5 ' 5 seconds before resetting the error message
                                   ' 5 секунд до сброса сообщения об ошибке
    m.errorResetTimer.repeat = false
    m.errorResetTimer.observeField("fire", "resetErrorState")
    m.top.appendChild(m.errorResetTimer)
    
    ' Create a timer to force playback if buffering takes too long
    ' Создать таймер для принудительного запуска воспроизведения, если буферизация занимает слишком много времени
    m.forcePlayTimer = createObject("roSGNode", "Timer")
    m.forcePlayTimer.id = "ForcePlayTimer"
    m.forcePlayTimer.duration = 3 ' Force playback after 3 seconds
                                  ' Принудительно запустить воспроизведение через 3 секунды
    
    ' Create a timeout timer for playlist loading
    ' Создать таймер ограничения времени загрузки плейлиста
    m.playlistLoadTimer = createObject("roSGNode", "Timer")
    m.playlistLoadTimer.id = "PlaylistLoadTimer"
    m.playlistLoadTimer.duration = m.playlistTimeoutSeconds
    m.playlistLoadTimer.repeat = false
    m.playlistLoadTimer.observeField("fire", "onPlaylistLoadTimeout")
    m.top.appendChild(m.playlistLoadTimer)

    m.forcePlayTimer.repeat = false
    m.forcePlayTimer.observeField("fire", "forcePlayVideo")
    m.top.appendChild(m.forcePlayTimer)
    
    ' Start loading the M3U playlist
    ' Начать загрузку M3U-плейлиста
    m.LoadTask = createObject("roSGNode", "ListaM3u")
    if m.LoadTask = invalid then print m.locale.ErrorLoadTaskMissing: return
    m.LoadTask.observeField("content", "rowListContentChanged")
    m.LoadTask.m3uUrl = m.global.lastUrl
    m.LoadTask.control = "RUN"
    print m.locale.StartingInitialLoadLog; m.global.lastUrl
    
    ' Set up field observers
    ' Настроить наблюдателей за полями
    m.nodes.RowList.observeField("rowItemSelected", "ChannelChange")
    m.nodes.RowList.observeField("rowItemFocused", "onRowItemFocused")
    m.nodes.Timer.observeField("fire", "restoreChannelCount")
    m.nodes.Video.observeField("state", "onVideoStateChange")
    m.nodes.Video.observeField("bufferingStatus", "onBufferingStatusChange")
end sub

sub applyLanguage()
    ' Apply localized strings to static interface elements
    ' Применить локализованные строки к статическим элементам интерфейса

    if m.nodes.MenuLabels.Home <> invalid then
        m.nodes.MenuLabels.Home.text = m.locale.Home
    end if

    if m.nodes.MenuLabels.Search <> invalid then
        m.nodes.MenuLabels.Search.text = m.locale.Search
    end if

    if m.nodes.MenuLabels.Playlist <> invalid then
        m.nodes.MenuLabels.Playlist.text = m.locale.ChangePlaylist
    end if
    
    if m.nodes.MenuLabels.Language <> invalid then
        m.nodes.MenuLabels.Language.text = m.locale.Language
    end if

    if m.totalChannels <> invalid then
        m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + m.totalChannels.toStr()
    else
        m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + "0"
    end if
end sub

sub updateLoadingProgress()
    ' Update the simulated loading progress
    ' Обновить имитацию прогресса загрузки
    if not m.isLoadingList then return

    m.loadingProgress += 5

    ' Limit the displayed progress to 99% until loading is complete
    ' Ограничить отображаемый прогресс 99% до завершения загрузки
    if m.loadingProgress > 99 then m.loadingProgress = 99

    ' Update the loading progress label
    ' Обновить текст с прогрессом загрузки
    m.nodes.Labels.ChannelCount.text = m.locale.LoadingChannels + m.loadingProgress.toStr() + "%"
end sub

sub onRowItemFocused()
    ' Handle changes to the currently focused item
    ' Обработать изменение текущего выбранного элемента
    focused = m.nodes.RowList.rowItemFocused

    ' Ensure the focus information is valid
    ' Убедиться, что информация о фокусе корректна
    if focused.count() <> 2 then return

    row = focused[0]
    itemIndex = focused[1]

    ' Validate row and item indices
    ' Проверить корректность индексов строки и элемента
    if row < 0 or row >= m.content.getChildCount() then return
    category = m.content.getChild(row)
    if itemIndex < 0 or itemIndex >= category.getChildCount() then return
    
    item = category.getChild(itemIndex)

    ' Hide additional information while loading placeholders
    ' Скрыть дополнительную информацию во время отображения заглушек
    if item = invalid or item.isLoading then
        m.nodes.InfoBar.visible = false
        m.nodes.PreviewPoster.visible = false
        return
    end if
    
    ' Update the information bar with the selected item
    ' Обновить информационную панель данными выбранного элемента
    m.nodes.Labels.Info.text = item.title
    m.nodes.InfoBar.visible = true

    ' Display the poster or a fallback image
    ' Показать постер или изображение по умолчанию
    if item.HDPosterUrl <> "" then
        m.nodes.PreviewPoster.uri = item.HDPosterUrl
    else
        m.nodes.PreviewPoster.uri = "pkg:/images/SINIMAGEN.PNG"
    end if

    ' Show or hide the preview poster depending on playback state
    ' Показать или скрыть постер предпросмотра в зависимости от состояния воспроизведения
    if m.nodes.Video.state = "playing" and not m.state.isFullScreen then
        m.nodes.PreviewPoster.visible = true
        m.nodes.FadeInPreview.control = "start"
    else if m.nodes.Video.state <> "playing" and not m.state.isFullScreen then
        m.nodes.PreviewPoster.visible = true
        m.nodes.FadeInPreview.control = "start"
    else
        m.nodes.FadeOutPreview.control = "start"
    end if

    ' Update the category labels
    ' Обновить названия категорий
    updateCategoryLabel(row)
end sub

sub updateCategoryLabel(row)
    ' Update the category labels shown in the interface
    ' Обновить названия категорий, отображаемых в интерфейсе
    totalRows = m.content.getChildCount()

    ' Nothing to update if there are no categories
    ' Нечего обновлять, если категории отсутствуют
    if totalRows = 0 then return

    m.nodes.Labels.Category.text = m.content.getChild(row).title

    ' Display the next category if available
    ' Отобразить следующую категорию, если она существует
    if row + 1 < totalRows then
        m.nodes.Labels.Category2.text = m.content.getChild(row + 1).title
    else
        m.nodes.Labels.Category2.text = ""
    end if
    
    ' Animate category changes when moving between rows
    ' Анимировать смену категорий при переходе между строками
    if m.state.lastRow <> row then
        scrolls = m.nodes.Scrolls
        isUp = m.state.lastRow > row or (m.state.lastRow = totalRows - 1 and row = 0)

        if isUp then
            scrolls.Up.control = "start"
        else
            scrolls.Down.control = "start"
        end if

        if m.nodes.Labels.Category2.text <> "" then
            if isUp then
                scrolls.Up2.control = "start"
            else
                scrolls.Down2.control = "start"
            end if
        end if

        ' Save the current row for the next comparison
        ' Сохранить текущую строку для следующего сравнения
        m.state.lastRow = row
    end if
end sub

sub ChannelChange()
    ' Handle channel selection
    ' Обработать выбор канала
    focused = m.nodes.RowList.rowItemFocused

    ' Validate the selected item and ensure it has a playable URL
    ' Проверить выбранный элемент и убедиться, что у него есть URL для воспроизведения
    if focused.count() <> 2 or m.content.getChild(focused[0]).getChild(focused[1]).url = "" then return

    item = m.content.getChild(focused[0]).getChild(focused[1])

    ' Ignore placeholder items while the playlist is loading
    ' Игнорировать элементы-заглушки во время загрузки плейлиста
    if item.isLoading then return
    
    video = m.nodes.Video

    ' If the selected channel is already playing, switch to fullscreen mode
    ' Если выбранный канал уже воспроизводится, перейти в полноэкранный режим
    if m.currentlyPlayingItem <> invalid and m.currentlyPlayingItem.url = item.url and not m.state.isFullScreen then
        video.translation = [0,0]
        video.width = 1920
        video.height = 1080
        video.enableUI = true
        setFullScreen(true)
    else
        ' Configure the video player for preview mode
        ' Настроить видеоплеер для режима предпросмотра
        if not m.state.isFullScreen then
            video.translation = [1200,0]
            video.width = 720
            video.height = 405
            video.enableUI = false
        end if

        ' Display the channel loading status
        ' Показать состояние загрузки канала
        m.nodes.Labels.ChannelCount.text = m.locale.LoadingChannel + "0%"

        ' Start playback of the selected channel
        ' Начать воспроизведение выбранного канала
        video.content = item
        video.control = "play"
        m.currentlyPlayingItem = item

        ' Hide the preview poster
        ' Скрыть постер предпросмотра
        m.nodes.FadeOutPreview.control = "start"

        ' Reset playback state
        ' Сбросить состояние воспроизведения
        m.errorState = false
        m.minBufferReached = false ' Reset the minimum buffering flag
                                   ' Сбросить флаг минимальной буферизации

        ' Start the timer that forces playback if buffering takes too long
        ' Запустить таймер принудительного запуска воспроизведения, если буферизация затянулась
        m.forcePlayTimer.control = "start"
    end if
end sub

sub setFullScreen(state)
    ' Update the fullscreen state
    ' Обновить состояние полноэкранного режима
    m.state.isFullScreen = state
    nodes = m.nodes

    ' Show or hide interface elements depending on fullscreen mode
    ' Показать или скрыть элементы интерфейса в зависимости от полноэкранного режима
    nodes.RowList.visible = not state
    nodes.Labels.Category.visible = not state
    nodes.Labels.Category2.visible = not state
    nodes.Labels.ChannelCount.visible = not state
    nodes.InfoBar.visible = not state
    nodes.Menu.visible = not state

    ' TODO: Simplify preview poster visibility logic (duplicate FadeOutPreview calls)
    ' TODO: Упростить логику отображения постера предпросмотра (дублируются вызовы FadeOutPreview)

    ' Update the preview poster visibility
    ' Обновить видимость постера предпросмотра
    if not state and nodes.Video.state <> "playing" then
        nodes.PreviewPoster.visible = true
        nodes.FadeInPreview.control = "start"
    else if state
        nodes.FadeOutPreview.control = "start"
    else
        nodes.FadeOutPreview.control = "start"
    end if

    ' Move focus to the appropriate component
    ' Переместить фокус на соответствующий компонент
    if state then
        nodes.Video.setFocus(true)
    else
        nodes.RowList.setFocus(true)

        ' TODO: Move preview mode configuration to a separate function
        ' TODO: Вынести настройку режима предпросмотра в отдельную функцию

        ' Restore the video player to preview mode
        ' Вернуть видеоплеер в режим предпросмотра
        nodes.Video.translation = [1200,0]
        nodes.Video.width = 720
        nodes.Video.height = 405
        nodes.Video.enableUI = false
    end if
end sub

function onKeyEvent(key, press) as boolean
    ' Ignore key-release events
    ' Игнорировать события отпускания кнопки
    if not press then return false

    ' Handle remote-control input while the video is in fullscreen mode
    ' Обработать команды пульта в полноэкранном режиме
    if m.state.isFullScreen then
        video = m.nodes.Video

        ' Exit fullscreen mode and restore the preview player
        ' Выйти из полноэкранного режима и восстановить окно предпросмотра
        if key = "back" then
            ' TODO: Move preview player configuration to a separate function
            ' TODO: Вынести настройку окна предпросмотра в отдельную функцию
            video.translation = [1200,0]
            video.width = 720
            video.height = 405
            video.enableUI = false
            setFullScreen(false)
            return true
        end if

        ' TODO: Toggle between pause and resume instead of always pausing
        ' TODO: Переключать паузу и продолжение вместо постоянной установки паузы
        if key = "play" or key = "pause" then video.control = "pause": return true

        ' Seek forward by 10 seconds
        ' Перемотать вперёд на 10 секунд
        if key = "fastforward" then video.seek = video.position + 10: return true

        ' Seek backward by 10 seconds
        ' Перемотать назад на 10 секунд
        if key = "rewind" then video.seek = video.position - 10: return true

        ' Consume all other key events while in fullscreen mode
        ' Перехватить все остальные нажатия в полноэкранном режиме
        return true
    end if
    
    ' Handle input while the sidebar menu is focused
    ' Обработать команды, когда фокус находится на боковом меню
    if m.state.menuFocused then
        itemsCount = m.nodes.MenuItems.getChildCount() - 1

        ' Close the sidebar menu and return focus to the channel list
        ' Закрыть боковое меню и вернуть фокус списку каналов
        if key = "right" or key = "back" then
            m.state.menuFocused = false
            m.nodes.RowList.setFocus(true)
            m.nodes.CollapseMenu.control = "start"
            hideMenuLabels()
            return true
        end if

        ' Move to the previous menu item
        ' Перейти к предыдущему пункту меню
        if key = "up" and m.state.menuItem > 0 then
            m.state.menuItem--
            updateMenuFocus()
            return true
        end if

        ' Move to the next menu item
        ' Перейти к следующему пункту меню
        if key = "down" and m.state.menuItem < itemsCount then
            m.state.menuItem++
            updateMenuFocus()
            return true
        end if

        ' Activate the selected menu item
        ' Активировать выбранный пункт меню
        if key = "OK" then
            selectMenuItem()
            return true
        end if
    else
        ' Open the sidebar menu
        ' Открыть боковое меню
        if key = "left" then
            m.state.menuFocused = true
            m.nodes.Menu.setFocus(true)
            m.nodes.ExpandMenu.control = "start"
            updateMenuFocus()
            return true
        end if

        ' Select or play the currently focused channel
        ' Выбрать или запустить текущий канал
        if key = "OK" then 
            ChannelChange()
            return true
        end if

        ' Handle the Back button outside the sidebar menu
        ' Обработать кнопку Back вне бокового меню
        if key = "back" then
            ' If the video is playing in the background and the sidebar is closed,
            ' switch to fullscreen mode
            ' Если видео воспроизводится в фоновом режиме и боковое меню закрыто,
            ' перейти в полноэкранный режим
            if m.nodes.Video.state = "playing" and not m.state.isFullScreen and not m.state.menuFocused then
                ' TODO: Move fullscreen player configuration to a separate function
                ' TODO: Вынести настройку полноэкранного плеера в отдельную функцию
                m.nodes.Video.translation = [0,0]
                m.nodes.Video.width = 1920
                m.nodes.Video.height = 1080
                m.nodes.Video.enableUI = true
                setFullScreen(true)
                return true
            end if

            ' Consume the Back button even when no action is performed
            ' Перехватить кнопку Back, даже если действие не выполнено
            return true
        end if
    end if

    ' Allow unhandled key events to propagate
    ' Разрешить дальнейшую обработку необработанных нажатий
    return false
end function

sub updateMenuFocus()
    ' Update the visual focus state of all sidebar menu items
    ' Обновить визуальное состояние фокуса всех пунктов бокового меню
    for i = 0 to m.nodes.MenuItems.getChildCount() - 1
        item = m.nodes.MenuItems.getChild(i)
        label = item.findNode("MenuLabel" + i.toStr())
        icon = item.findNode("IconHighlight" + i.toStr())

        ' Show the menu label while the sidebar is expanded
        ' Показать подпись пункта меню, пока боковое меню раскрыто
        label.visible = true

        ' Highlight the currently selected menu item
        ' Выделить текущий выбранный пункт меню
        if i = m.state.menuItem then
            label.color = "0xFFFF00FF"
            icon.visible = true
        else
            label.color = "0xFFFFFFFF"
            icon.visible = false
        end if
    end for
end sub

sub hideMenuLabels()
    ' Hide all sidebar labels and focus indicators
    ' Скрыть все подписи и индикаторы фокуса бокового меню
    for i = 0 to m.nodes.MenuItems.getChildCount() - 1
        item = m.nodes.MenuItems.getChild(i)
        item.findNode("MenuLabel" + i.toStr()).visible = false
        item.findNode("IconHighlight" + i.toStr()).visible = false
    end for
end sub

sub selectMenuItem()
    ' Close the sidebar menu before processing the selected item
    ' Закрыть боковое меню перед обработкой выбранного пункта
    m.state.menuFocused = false
    m.nodes.CollapseMenu.control = "start"
    hideMenuLabels()

    ' Return focus to the channel list when Home is selected
    ' Вернуть фокус списку каналов при выборе пункта «Главная»
    if m.state.menuItem = 0 then
        m.nodes.RowList.setFocus(true)
        return
    end if

    ' Open the search dialog
    ' Открыть диалог поиска
    if m.state.menuItem = 1 then
        kb = createObject("roSGNode", "KeyboardDialog")
        if kb = invalid then return

        kb.backgroundUri = "pkg:/images/FONDO.PNG"
        kb.title = m.locale.SearchContent
        kb.text = ""
        kb.buttons = [m.locale.Search, m.locale.Cancel]
        kb.observeField("buttonSelected", "onSearchButtonPressed")
        m.top.dialog = kb
        return
    end if

    ' Open the saved playlist list
    ' Открыть список сохранённых плейлистов
    if m.state.menuItem = 2 then
        openPlaylistDialog()
        return
    end if

    ' TODO:
    ' Open the language selection dialog.
    ' Открыть диалог выбора языка.
    if m.state.menuItem = 3 then
        languages = getAvailableLanguages()

        dialog = createObject("roSGNode", "Dialog")
        if dialog = invalid then return

        dialog.title = m.locale.Language

        buttons = []

        for each lang in languages
            buttons.push(lang.name)
        end for

        buttons.push(m.locale.Cancel)

        dialog.buttons = buttons
        dialog.observeField("buttonSelected", "onLanguageSelected")

        m.top.dialog = dialog
        return
    end if
end sub

sub onSearchButtonPressed()
    ' Retrieve the active search dialog
    ' Получить активный диалог поиска
    kb = m.top.dialog

    ' Stop if the dialog is unavailable
    ' Остановить выполнение, если диалог недоступен
    if kb = invalid then print m.locale.ErrorInvalidSearchDialog: return

    ' Apply the search filter when the Search button is selected
    ' Применить фильтр поиска при выборе кнопки поиска
    if kb.buttonSelected = 0 and kb.text <> "" then
        filterContent(kb.text)
    end if

    ' Close the dialog and return focus to the channel list
    ' Закрыть диалог и вернуть фокус списку каналов
    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub loadPlaylist(url as string)
    ' Load the specified playlist URL
    ' Загрузить плейлист по указанному URL

    if url = "" then return

    m.nodes.Labels.ChannelCount.text = m.locale.LoadingChannels + "0%"
    m.global.lastUrl = url

    ' Restart the playlist loading task
    ' Перезапустить задачу загрузки плейлиста
    m.LoadTask.control = "STOP"
    m.LoadTask.m3uUrl = url
    m.LoadTask.control = "RUN"

    ' Reset category labels and start loading animations
    ' Сбросить названия категорий и запустить анимации загрузки
    m.nodes.Labels.Category.text = m.locale.Loading
    m.nodes.Labels.Category2.text = m.locale.Loading
    m.nodes.LoadingAnim1.control = "start"
    m.nodes.LoadingAnim2.control = "start"

    ' Replace the current content with loading placeholders
    ' Заменить текущее содержимое заглушками загрузки
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)

    for i = 0 to 1
        cat = createObject("roSGNode", "ContentNode")
        cat.title = m.locale.Loading

        for j = 0 to 19
            item = createObject("roSGNode", "ContentNode")
            item.addField("isLoading", "boolean", true)
            item.isLoading = true
            cat.appendChild(item)
        end for

        m.content.appendChild(cat)
    end for

    m.nodes.RowList.content = m.content

    ' Restart loading progress tracking
    ' Перезапустить отслеживание прогресса загрузки
    m.isLoadingList = true
    m.loadingProgress = 0
    m.loadingTimer.control = "start"
    m.playlistLoadTimer.control = "stop"
    m.playlistLoadTimer.duration = m.playlistTimeoutSeconds
    m.playlistLoadTimer.control = "start"
end sub

sub onUrlButtonPressed()
    ' Retrieve the active playlist URL dialog
    ' Получить активный диалог ввода URL плейлиста
    kb = m.top.dialog

    ' Stop if the dialog is unavailable
    ' Остановить выполнение, если диалог недоступен
    if kb = invalid then print m.locale.ErrorInvalidUrlDialog: return

    ' Load the playlist URL entered by the user
    ' Загрузить URL плейлиста, введённый пользователем
    if kb.buttonSelected = 0 and kb.text <> "" then
        saveRecentUrl(kb.text)
        loadPlaylist(kb.text)

    ' Restore the original playlist URL
    ' Восстановить исходный URL плейлиста
    else if kb.buttonSelected = 2 then
        saveRecentUrl(m.originalUrl)
        loadPlaylist(m.originalUrl)
    end if

    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub onLanguageSelected()

    dialog = m.top.dialog
    if dialog = invalid then return

    languages = getAvailableLanguages()

    if dialog.buttonSelected < languages.count() then

        selected = languages[dialog.buttonSelected]

        m.languageCode = selected.code
        saveLanguage(m.languageCode)
        m.locale = loadLanguage(m.languageCode)
        applyLanguage()

    end if

    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)

end sub

sub rowListContentChanged()
    ' Rebuild the channel list after playlist loading completes
    ' Перестроить список каналов после завершения загрузки плейлиста
    channels = 0

    ' Remove the current placeholder or previous content
    ' Удалить текущие заглушки или предыдущее содержимое
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)

    ' Clone each loaded category and its channel items
    ' Клонировать каждую загруженную категорию и её каналы
    for each cat in m.LoadTask.content.getChildren(-1, 0)
        categoryClone = cat.clone(true)

        ' Mark all cloned items as fully loaded
        ' Отметить все клонированные элементы как полностью загруженные
        for each item in categoryClone.getChildren(-1, 0)
            item.addField("isLoading", "boolean", true)
            item.isLoading = false
        end for

        m.content.appendChild(categoryClone)
        channels += categoryClone.getChildCount()
    end for

    ' Apply the loaded content to the channel list
    ' Применить загруженное содержимое к списку каналов
    m.nodes.RowList.content = m.content
    m.totalChannels = channels
    m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + channels.toStr()

    ' Stop loading animations and restore label opacity
    ' Остановить анимации загрузки и восстановить непрозрачность подписей
    m.nodes.LoadingAnim1.control = "stop"
    m.nodes.LoadingAnim2.control = "stop"
    m.nodes.Labels.Category.opacity = 1.0
    m.nodes.Labels.Category2.opacity = 1.0

    ' Stop loading progress tracking
    ' Остановить отслеживание прогресса загрузки
    m.isLoadingList = false
    m.loadingTimer.control = "stop"
    m.playlistLoadTimer.control = "stop"

    ' Display the first and second category labels when available
    ' Отобразить названия первой и второй категорий, если они доступны
    if m.content.getChildCount() > 0 then
        m.nodes.Labels.Category.text = m.content.getChild(0).title
        if m.content.getChildCount() > 1 then
            m.nodes.Labels.Category2.text = m.content.getChild(1).title
        else
            m.nodes.Labels.Category2.text = ""
        end if
    else
        ' Clear category labels if the playlist contains no categories
        ' Очистить названия категорий, если плейлист не содержит категорий
        m.nodes.Labels.Category.text = ""
        m.nodes.Labels.Category2.text = ""
    end if

    ' Log the number of loaded channels and categories
    ' Вывести в журнал количество загруженных каналов и категорий
    print m.locale.ContentLoadedLog; channels; m.locale.ChannelsInLog; m.content.getChildCount(); m.locale.CategoriesLog
end sub

sub restoreChannelCount()
    ' Restore the total channel count when no error is active
    ' Восстановить общее количество каналов, если состояние ошибки не активно
    if not m.errorState then
        m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + m.totalChannels.toStr()
    end if
end sub

sub onVideoStateChange()
    ' Handle changes in the video playback state
    ' Обработать изменения состояния воспроизведения видео
    state = m.nodes.Video.state
    print m.locale.VideoStateChangedLog; state

    ' Update the interface while the channel is buffering
    ' Обновить интерфейс во время буферизации канала
    if state = "buffering" then
        m.nodes.Labels.ChannelCount.text = m.locale.LoadingChannel + "0%"

    ' Handle successful playback startup
    ' Обработать успешный запуск воспроизведения
    else if state = "playing" then
        m.nodes.Labels.ChannelCount.text = m.locale.ChannelLoaded
        m.nodes.FadeOutPreview.control = "start"
        m.nodes.Timer.control = "start"
        m.errorState = false
        m.minBufferReached = true ' Minimum buffering threshold reached; allow continuous playback
                                  ' Достигнут минимальный порог буферизации; разрешить непрерывное воспроизведение
        m.forcePlayTimer.control = "stop" ' Stop the forced-playback timer
                                          ' Остановить таймер принудительного запуска воспроизведения

    ' Handle playback errors
    ' Обработать ошибки воспроизведения
    else if state = "error" then
        m.nodes.Labels.ChannelCount.text = m.locale.LinkFailed

        ' Restore the preview poster outside fullscreen mode
        ' Восстановить постер предпросмотра вне полноэкранного режима
        if not m.state.isFullScreen then
            m.nodes.PreviewPoster.visible = true
            m.nodes.FadeInPreview.control = "start"
        end if

        m.errorState = true
        m.errorResetTimer.control = "start"
        m.forcePlayTimer.control = "stop" ' Stop the timer when an error occurs
                                          ' Остановить таймер при возникновении ошибки

    ' Handle stopped or completed playback
    ' Обработать остановленное или завершённое воспроизведение
    else if state = "stopped" or state = "finished" then
        if m.errorState then
            m.nodes.Labels.ChannelCount.text = m.locale.LinkFailed
        else
            m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + m.totalChannels.toStr()

            ' Restore the preview poster outside fullscreen mode
            ' Восстановить постер предпросмотра вне полноэкранного режима
            if not m.state.isFullScreen then
                m.nodes.PreviewPoster.visible = true
                m.nodes.FadeInPreview.control = "start"
            end if
        end if

        m.forcePlayTimer.control = "stop" ' Stop the timer when video playback stops
                                          ' Остановить таймер при остановке воспроизведения
    end if

    ' TODO: Move preview player configuration to a separate function
    ' TODO: Вынести настройку окна предпросмотра в отдельную функцию

    ' Restore the video player to preview mode when not fullscreen
    ' Вернуть видеоплеер в режим предпросмотра вне полноэкранного режима
    if not m.state.isFullScreen then
        m.nodes.Video.translation = [1200,0]
        m.nodes.Video.width = 720
        m.nodes.Video.height = 405
        m.nodes.Video.enableUI = false
    end if
end sub

sub onBufferingStatusChange()
    ' Handle buffering progress updates
    ' Обработать обновления прогресса буферизации
    status = m.nodes.Video.bufferingStatus

    ' Validate buffering information before updating the interface
    ' Проверить данные буферизации перед обновлением интерфейса
    if status <> invalid and status.percentage <> invalid and m.nodes.Video.state = "buffering" then
        m.nodes.Labels.ChannelCount.text = m.locale.LoadingChannel + status.percentage.toStr() + "%"

        ' Start playback after reaching 5% buffering for a faster startup
        ' Начать воспроизведение после достижения 5% буферизации для более быстрого запуска
        if status.percentage >= 5 and not m.minBufferReached then
            ' TODO: Verify whether sending "play" during buffering improves startup reliability
            ' TODO: Проверить, действительно ли команда "play" во время буферизации улучшает надёжность запуска
            m.nodes.Video.control = "play"
            m.minBufferReached = true
            m.forcePlayTimer.control = "stop" ' Stop the timer after reaching the buffering threshold
                                              ' Остановить таймер после достижения порога буферизации
        end if
    end if
end sub

sub forcePlayVideo()
    ' Force playback if buffering takes too long
    ' Принудительно запустить воспроизведение, если буферизация занимает слишком много времени
    if m.nodes.Video.state = "buffering" and not m.minBufferReached then
        print m.locale.ForcePlaybackLog

        ' TODO: Verify whether forced playback is necessary for Roku Video nodes
        ' TODO: Проверить, необходим ли принудительный запуск для узлов Roku Video
        m.nodes.Video.control = "play"
        m.minBufferReached = true
    end if
end sub

sub resetErrorState()
    ' Clear the current playback error state
    ' Сбросить текущее состояние ошибки воспроизведения
    m.errorState = false

    ' Restore the total channel count after playback stops
    ' Восстановить общее количество каналов после остановки воспроизведения
    if m.nodes.Video.state = "stopped" or m.nodes.Video.state = "finished" then
        m.nodes.Labels.ChannelCount.text = m.locale.ChannelsLoaded + m.totalChannels.toStr()
    end if
end sub

sub filterContent(term)
    ' Remove the currently displayed content before applying the filter
    ' Удалить текущее отображаемое содержимое перед применением фильтра
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)

    ' Create a separate row for search results
    ' Создать отдельную строку для результатов поиска
    searchRow = createObject("roSGNode", "ContentNode")
    searchRow.title = m.locale.SearchPrefix + term
    termLower = lcase(term)

    ' Search all channels across all loaded categories
    ' Выполнить поиск по всем каналам во всех загруженных категориях
    for each cat in m.LoadTask.content.getChildren(-1, 0)
        for each ch in cat.getChildren(-1, 0)
            if lcase(ch.title).instr(termLower) >= 0 then
                chClone = ch.clone(true)
                chClone.addField("isLoading", "boolean", true)
                chClone.isLoading = false
                searchRow.appendChild(chClone)
            end if
        end for
    end for

    ' Add the search results row only when matches are found
    ' Добавить строку результатов поиска только при наличии совпадений
    if searchRow.getChildCount() > 0 then m.content.appendChild(searchRow)

    ' Append all original categories after the search results
    ' Добавить все исходные категории после результатов поиска
    for each cat in m.LoadTask.content.getChildren(-1, 0)
        categoryClone = cat.clone(true)

        ' Mark all cloned category items as fully loaded
        ' Отметить все клонированные элементы категорий как полностью загруженные
        for each item in categoryClone.getChildren(-1, 0)
            item.addField("isLoading", "boolean", true)
            item.isLoading = false
        end for

        m.content.appendChild(categoryClone)
    end for

    ' Apply the filtered content to the channel list
    ' Применить отфильтрованное содержимое к списку каналов
    m.nodes.RowList.content = m.content
    count = searchRow.getChildCount()

    ' Display the number of matching results
    ' Отобразить количество найденных результатов
    if count > 0 then
        m.nodes.Labels.ChannelCount.text = m.locale.Results + count.toStr()
        m.nodes.RowList.jumpToRowItem = [0, 0]
        updateCategoryLabel(0)
    else
        ' Clear category labels when no matches are found
        ' Очистить названия категорий, если совпадения не найдены
        m.nodes.Labels.ChannelCount.text = m.locale.NoResults
        m.nodes.Labels.Category.text = ""
        m.nodes.Labels.Category2.text = ""
    end if

    ' Log the applied filter and result count
    ' Вывести в журнал применённый фильтр и количество результатов
    print m.locale.FilterAppliedLog; count; m.locale.ResultsForLog; term
end sub

function loadRecentUrls() as object
    ' Load recently used M3U playlist URLs from the registry
    ' Загрузить недавно использованные URL M3U-плейлистов из реестра
    registry = createObject("roRegistrySection", "RecentM3UUrls")
    urls = []

    ' Read up to three saved playlist URLs
    ' Прочитать до трёх сохранённых URL плейлистов
    for i = 1 to 3
        key = "url" + i.toStr()

        ' Add the saved URL only if the registry entry exists and is not empty
        ' Добавить сохранённый URL только в том случае, если запись существует и не пуста
        if registry.exists(key) then
            url = registry.read(key)
            if url <> invalid and url <> "" then
                urls.push(url)
            end if
        end if
    end for

    return urls
end function

sub saveRecentUrl(url as string)
    ' Build a new recent URL list without duplicates
    ' Сформировать новый список последних URL без дубликатов
    newUrls = []
    found = false

    ' Copy all existing URLs except the one being saved
    ' Скопировать все существующие URL, кроме сохраняемого
    for each u in m.recentUrls
        if u = url then
            found = true
        else
            newUrls.push(u)
        end if
    end for
    
    ' Add the current URL to the beginning of the list
    ' Добавить текущий URL в начало списка
    newUrls.unshift(url)

    ' Keep only the three most recent URLs
    ' Сохранить только три последних URL
    if newUrls.count() > 3 then
        newUrls = newUrls.slice(0, 3)
    end if

    m.recentUrls = newUrls
    
    ' Save the updated URL history to the registry
    ' Сохранить обновлённую историю URL в реестр
    registry = createObject("roRegistrySection", "RecentM3UUrls")
    for i = 0 to m.recentUrls.count() - 1
        key = "url" + (i + 1).toStr()
        registry.write(key, m.recentUrls[i])
    end for

    registry.flush()
end sub

function loadPlaylists() as object
    ' Load saved playlists from the registry
    ' Загрузить сохранённые плейлисты из реестра
    playlists = []
    registry = createObject("roRegistrySection", "Playlists")

    if registry = invalid then return playlists

    if registry.exists("items") then
        jsonText = registry.read("items")

        if jsonText <> invalid and jsonText <> "" then
            savedPlaylists = parseJson(jsonText)

            if savedPlaylists <> invalid and type(savedPlaylists) = "roArray" then
                playlists = savedPlaylists
            end if
        end if
    end if

    return playlists
end function

sub savePlaylists(playlists as object)
    ' Save the playlist collection to the registry as JSON
    ' Сохранить коллекцию плейлистов в реестр в формате JSON
    registry = createObject("roRegistrySection", "Playlists")

    if registry = invalid then return

    registry.write("items", formatJson(playlists))
    registry.flush()
end sub

sub addPlaylist(name as string, url as string)
    ' Add a playlist or move an existing playlist to the beginning
    ' Добавить плейлист или переместить существующий плейлист в начало
    if name = "" or url = "" then return

    if m.playlists = invalid then
        m.playlists = []
    end if

    updatedPlaylists = []

    ' Remove an existing playlist with the same URL
    ' Удалить существующий плейлист с таким же URL
    for each playlist in m.playlists
        if playlist.url <> url then
            updatedPlaylists.push(playlist)
        end if
    end for

    newPlaylist = {
        name: name
        url: url
    }

    updatedPlaylists.unshift(newPlaylist)

    ' Keep no more than 20 saved playlists
    ' Хранить не более 20 сохранённых плейлистов
    if updatedPlaylists.count() > 20 then
        updatedPlaylists = updatedPlaylists.slice(0, 20)
    end if

    m.playlists = updatedPlaylists
    savePlaylists(m.playlists)
end sub

sub openPlaylistDialog()
    ' Create the saved playlist selection dialog
    ' Создать диалог выбора сохранённого плейлиста
    dialog = createObject("roSGNode", "Dialog")
    if dialog = invalid then return

    dialog.title = m.locale.MyPlaylists

    buttons = []

    ' Add all saved playlists to the dialog
    ' Добавить все сохранённые плейлисты в диалог
    if m.playlists <> invalid then
        for each playlist in m.playlists
            if playlist.name <> invalid and playlist.name <> "" then
                buttons.push(playlist.name)
            end if
        end for
    end if

    ' Save the number of playlist buttons
    ' Сохранить количество кнопок плейлистов
    m.playlistButtonCount = buttons.count()

    buttons.push(m.locale.AddPlaylist)
    buttons.push(m.locale.DefaultPlaylist)
    buttons.push(m.locale.SetPlaylistTimeout)
    buttons.push(m.locale.Cancel)

    dialog.buttons = buttons
    dialog.observeField("buttonSelected", "onPlaylistSelected")

    m.top.dialog = dialog
end sub

sub onPlaylistSelected()
    ' Handle playlist selection
    ' Обработать выбор плейлиста
    dialog = m.top.dialog
    if dialog = invalid then return

    index = dialog.buttonSelected

    ' Close the current playlist list before performing the next action
    ' Закрыть текущий список плейлистов перед следующим действием
    m.top.dialog = invalid

    ' Existing playlist selected
    ' Выбран существующий плейлист
    if index >= 0 and index < m.playlistButtonCount then
        m.selectedPlaylistIndex = index
        openPlaylistActionDialog()
        return
    end if

    ' Add a new playlist
    ' Добавить новый плейлист
    if index = m.playlistButtonCount then
        openAddPlaylistNameDialog()
        return
    end if

    ' Load the default playlist
    ' Загрузить исходный плейлист
    if index = m.playlistButtonCount + 1 then
        loadPlaylist(m.originalUrl)
        m.nodes.RowList.setFocus(true)
        return
    end if

    ' Open the playlist timeout setting dialog
    ' Открыть диалог настройки тайм-аута загрузки плейлиста
    if index = m.playlistButtonCount + 2 then
        openPlaylistTimeoutDialog()
        return
    end if

    ' Cancel or close the dialog
    ' Отменить действие или закрыть диалог
    m.nodes.RowList.setFocus(true)
end sub

sub openPlaylistActionDialog()
    ' Open actions for the selected playlist
    ' Открыть действия для выбранного плейлиста
    if m.selectedPlaylistIndex = invalid then return
    if m.selectedPlaylistIndex < 0 or m.selectedPlaylistIndex >= m.playlists.count() then return

    playlist = m.playlists[m.selectedPlaylistIndex]

    dialog = createObject("roSGNode", "Dialog")
    if dialog = invalid then
        m.nodes.RowList.setFocus(true)
        return
    end if

    dialog.title = playlist.name
    dialog.buttons = [
        m.locale.Load
        m.locale.DeletePlaylist
        m.locale.Cancel
    ]

    dialog.observeField("buttonSelected", "onPlaylistActionSelected")
    m.top.dialog = dialog
end sub

sub onPlaylistActionSelected()
    ' Handle an action for the selected playlist
    ' Обработать действие для выбранного плейлиста
    dialog = m.top.dialog
    if dialog = invalid then return

    index = m.selectedPlaylistIndex
    button = dialog.buttonSelected

    m.top.dialog = invalid

    if index = invalid or index < 0 or index >= m.playlists.count() then
        m.selectedPlaylistIndex = invalid
        m.nodes.RowList.setFocus(true)
        return
    end if

    playlist = m.playlists[index]

    ' Load the selected playlist
    ' Загрузить выбранный плейлист
    if button = 0 then
        m.selectedPlaylistIndex = invalid
        loadPlaylist(playlist.url)
        m.nodes.RowList.setFocus(true)
        return
    end if

    ' Delete the selected playlist
    ' Удалить выбранный плейлист
    if button = 1 then
        deletePlaylist(index)
        m.selectedPlaylistIndex = invalid
        openPlaylistDialog()
        return
    end if

    m.selectedPlaylistIndex = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub deletePlaylist(index as integer)
    ' Delete a saved playlist
    ' Удалить сохранённый плейлист
    if m.playlists = invalid then return
    if index < 0 or index >= m.playlists.count() then return

    m.playlists.delete(index)
    savePlaylists(m.playlists)
end sub



sub openAddPlaylistNameDialog()
    ' Open a keyboard dialog for the playlist name
    ' Открыть экранную клавиатуру для названия плейлиста
    kb = createObject("roSGNode", "KeyboardDialog")
    if kb = invalid then
        m.nodes.RowList.setFocus(true)
        return
    end if

    kb.backgroundUri = "pkg:/images/FONDO.PNG"
    kb.title = m.locale.EnterPlaylistName
    kb.text = ""
    kb.buttons = [
        m.locale.AddPlaylist
        m.locale.Cancel
    ]
    kb.observeField("buttonSelected", "onPlaylistNameEntered")

    m.top.dialog = kb
end sub

sub onPlaylistNameEntered()
    ' Handle the entered playlist name
    ' Обработать введённое название плейлиста
    kb = m.top.dialog
    if kb = invalid then return

    if kb.buttonSelected = 0 and kb.text <> "" then
        m.pendingPlaylistName = kb.text
        m.top.dialog = invalid
        openAddPlaylistUrlDialog()
        return
    end if

    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub openAddPlaylistUrlDialog()
    ' Open a keyboard dialog for the playlist URL
    ' Открыть экранную клавиатуру для URL плейлиста
    kb = createObject("roSGNode", "KeyboardDialog")
    if kb = invalid then
        m.pendingPlaylistName = invalid
        m.nodes.RowList.setFocus(true)
        return
    end if

    kb.backgroundUri = "pkg:/images/FONDO.PNG"
    kb.title = m.locale.EnterPlaylistUrl
    kb.text = ""
    kb.buttons = [
        m.locale.AddPlaylist
        m.locale.Cancel
    ]
    kb.observeField("buttonSelected", "onPlaylistUrlEntered")

    m.top.dialog = kb
end sub

sub onPlaylistUrlEntered()
    ' Save and load the new playlist
    ' Сохранить и загрузить новый плейлист
    kb = m.top.dialog
    if kb = invalid then return

    if kb.buttonSelected = 0 and kb.text <> "" and m.pendingPlaylistName <> invalid then
        playlistName = m.pendingPlaylistName
        playlistUrl = kb.text

        addPlaylist(playlistName, playlistUrl)
        saveRecentUrl(playlistUrl)

        m.pendingPlaylistName = invalid
        m.top.dialog = invalid

        loadPlaylist(playlistUrl)
        m.nodes.RowList.setFocus(true)
        return
    end if

    m.pendingPlaylistName = invalid
    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub onPlaylistLoadTimeout()
    ' Stop playlist loading after the timeout
    ' Остановить загрузку плейлиста после истечения времени
    if not m.isLoadingList then return

    m.LoadTask.control = "STOP"
    m.isLoadingList = false
    m.loadingTimer.control = "stop"

    m.nodes.LoadingAnim1.control = "stop"
    m.nodes.LoadingAnim2.control = "stop"

    m.nodes.Labels.ChannelCount.text = m.locale.PlaylistLoadFailed
    m.nodes.Labels.Category.text = ""
    m.nodes.Labels.Category2.text = ""

    m.nodes.RowList.setFocus(true)
end sub

function loadPlaylistTimeout() as integer
    ' Load the playlist loading timeout from the registry
    ' Загрузить тайм-аут загрузки плейлиста из реестра
    defaultTimeout = 20
    registry = createObject("roRegistrySection", "Settings")

    if registry = invalid then return defaultTimeout

    if registry.exists("playlistLoadTimeout") then
        savedValue = registry.read("playlistLoadTimeout")

        if savedValue <> invalid and savedValue <> "" then
            timeout = int(val(savedValue))

            if timeout >= 5 and timeout <= 300 then
                return timeout
            end if
        end if
    end if

    return defaultTimeout
end function

sub savePlaylistTimeout(timeout as integer)
    ' Save the playlist loading timeout to the registry
    ' Сохранить тайм-аут загрузки плейлиста в реестр
    registry = createObject("roRegistrySection", "Settings")
    if registry = invalid then return

    registry.write("playlistLoadTimeout", timeout.toStr())
    registry.flush()
end sub

sub openPlaylistTimeoutDialog()
    ' Open a keyboard dialog for the loading timeout
    ' Открыть экранную клавиатуру для ввода тайм-аута загрузки
    kb = createObject("roSGNode", "KeyboardDialog")

    if kb = invalid then
        m.nodes.RowList.setFocus(true)
        return
    end if

    kb.backgroundUri = "pkg:/images/FONDO.PNG"
    kb.title = m.locale.EnterPlaylistTimeout
    kb.text = m.playlistTimeoutSeconds.toStr()
    kb.buttons = [
        m.locale.Load
        m.locale.Cancel
    ]
    kb.observeField("buttonSelected", "onPlaylistTimeoutEntered")

    m.top.dialog = kb
end sub

sub onPlaylistTimeoutEntered()
    ' Validate and save the playlist loading timeout
    ' Проверить и сохранить тайм-аут загрузки плейлиста
    kb = m.top.dialog
    if kb = invalid then return

    if kb.buttonSelected = 0 then
        timeout = int(val(kb.text))

        if timeout >= 5 and timeout <= 300 then
            m.playlistTimeoutSeconds = timeout
            savePlaylistTimeout(timeout)

            if m.playlistLoadTimer <> invalid then
                m.playlistLoadTimer.duration = timeout
            end if

            m.top.dialog = invalid
            openPlaylistDialog()
            return
        end if

        kb.title = m.locale.InvalidPlaylistTimeout
        return
    end if

    m.top.dialog = invalid
    openPlaylistDialog()
end sub