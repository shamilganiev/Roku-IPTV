sub init()
    ' Simplificar estructura de nodos
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
        ExpandMenu: m.top.findNode("ExpandMenu"),
        CollapseMenu: m.top.findNode("CollapseMenu"),
        LoadingAnim1: m.top.findNode("LoadingAnimation1"),
        LoadingAnim2: m.top.findNode("LoadingAnimation2")
    }

    ' Configurar el nodo Video para optimizar el inicio
    m.nodes.Video.enableUI = false
    m.nodes.Video.loop = true
    m.nodes.Video.enableTrickPlay = true

    ' Definir el URL original y cargar los últimos links desde el registro
    m.originalUrl = "https://raw.githubusercontent.com/smolnp/IPTVru/refs/heads/gh-pages/IPTVstable.m3u8" ' URL original
    m.global.addFields({lastUrl: m.originalUrl})
    m.state = {isFullScreen: false, lastRow: 0, menuItem: 0, menuFocused: false}
    m.recentUrls = loadRecentUrls() ' Cargar los links recientes
    if m.recentUrls.count() > 0 then
        m.global.lastUrl = m.recentUrls[0] ' Usar el último link guardado como predeterminado
    end if

    ' Inicializar contenido con placeholders
    m.content = createObject("roSGNode", "ContentNode")
    for i = 0 to 1
        cat = createObject("roSGNode", "ContentNode")
        cat.title = "Cargando..."
        for j = 0 to 19
            item = createObject("roSGNode", "ContentNode")
            item.addField("isLoading", "boolean", true)
            item.isLoading = true
            cat.appendChild(item)
        end for
        m.content.appendChild(cat)
    end for
    
    ' Configurar interfaz inicial
    m.nodes.RowList.content = m.content
    m.nodes.RowList.setFocus(true)
    m.nodes.Labels.Category.text = "Cargando..."
    m.nodes.Labels.Category2.text = "Cargando..."
    m.nodes.LoadingAnim1.control = "start"
    m.nodes.LoadingAnim2.control = "start"
    
    ' Configurar temporizador de progreso
    m.loadingTimer = m.top.findNode("LoadingProgressTimer")
    m.loadingTimer.observeField("fire", "updateLoadingProgress")
    m.loadingProgress = 0
    m.isLoadingList = true
    m.loadingTimer.control = "start"
    
    ' Crear un temporizador para resetear el estado de error
    m.errorResetTimer = createObject("roSGNode", "Timer")
    m.errorResetTimer.id = "ErrorResetTimer"
    m.errorResetTimer.duration = 5 ' 5 segundos antes de resetear el mensaje de error
    m.errorResetTimer.repeat = false
    m.errorResetTimer.observeField("fire", "resetErrorState")
    m.top.appendChild(m.errorResetTimer)
    
    ' Crear un temporizador para forzar la reproducción si el buffering tarda demasiado
    m.forcePlayTimer = createObject("roSGNode", "Timer")
    m.forcePlayTimer.id = "ForcePlayTimer"
    m.forcePlayTimer.duration = 3 ' 3 segundos antes de forzar la reproducción
    m.forcePlayTimer.repeat = false
    m.forcePlayTimer.observeField("fire", "forcePlayVideo")
    m.top.appendChild(m.forcePlayTimer)
    
    ' Iniciar carga de lista M3U
    m.LoadTask = createObject("roSGNode", "ListaM3u")
    if m.LoadTask = invalid then print "Error: ListaM3u no encontrado": return
    m.LoadTask.observeField("content", "rowListContentChanged")
    m.LoadTask.m3uUrl = m.global.lastUrl
    m.LoadTask.control = "RUN"
    print "Iniciando carga inicial con: "; m.global.lastUrl
    
    ' Configurar observadores
    m.nodes.RowList.observeField("rowItemSelected", "ChannelChange")
    m.nodes.RowList.observeField("rowItemFocused", "onRowItemFocused")
    m.nodes.Timer.observeField("fire", "restoreChannelCount")
    m.nodes.Video.observeField("state", "onVideoStateChange")
    m.nodes.Video.observeField("bufferingStatus", "onBufferingStatusChange")
end sub

sub updateLoadingProgress()
    if not m.isLoadingList then return
    m.loadingProgress += 5
    if m.loadingProgress > 99 then m.loadingProgress = 99
    m.nodes.Labels.ChannelCount.text = "Cargando canales: " + m.loadingProgress.toStr() + "%"
end sub

sub onRowItemFocused()
    focused = m.nodes.RowList.rowItemFocused
    if focused.count() <> 2 then return
    row = focused[0]
    itemIndex = focused[1]
    if row < 0 or row >= m.content.getChildCount() then return
    category = m.content.getChild(row)
    if itemIndex < 0 or itemIndex >= category.getChildCount() then return
    
    item = category.getChild(itemIndex)
    if item = invalid or item.isLoading then
        m.nodes.InfoBar.visible = false
        m.nodes.PreviewPoster.visible = false
        return
    end if
    
    m.nodes.Labels.Info.text = item.title
    m.nodes.InfoBar.visible = true
    if item.HDPosterUrl <> "" then
        m.nodes.PreviewPoster.uri = item.HDPosterUrl
    else
        m.nodes.PreviewPoster.uri = "pkg:/images/SINIMAGEN.PNG"
    end if

    if m.nodes.Video.state = "playing" and not m.state.isFullScreen then
        m.nodes.PreviewPoster.visible = true
        m.nodes.FadeInPreview.control = "start"
    else if m.nodes.Video.state <> "playing" and not m.state.isFullScreen then
        m.nodes.PreviewPoster.visible = true
        m.nodes.FadeInPreview.control = "start"
    else
        m.nodes.FadeOutPreview.control = "start"
    end if
    updateCategoryLabel(row)
end sub

sub updateCategoryLabel(row)
    totalRows = m.content.getChildCount()
    if totalRows = 0 then return
    m.nodes.Labels.Category.text = m.content.getChild(row).title
    if row + 1 < totalRows then
        m.nodes.Labels.Category2.text = m.content.getChild(row + 1).title
    else
        m.nodes.Labels.Category2.text = ""
    end if
    
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
        m.state.lastRow = row
    end if
end sub

sub ChannelChange()
    focused = m.nodes.RowList.rowItemFocused
    if focused.count() <> 2 or m.content.getChild(focused[0]).getChild(focused[1]).url = "" then return
    item = m.content.getChild(focused[0]).getChild(focused[1])
    if item.isLoading then return
    
    video = m.nodes.Video
    if m.currentlyPlayingItem <> invalid and m.currentlyPlayingItem.url = item.url and not m.state.isFullScreen then
        video.translation = [0,0]
        video.width = 1920
        video.height = 1080
        video.enableUI = true
        setFullScreen(true)
    else
        if not m.state.isFullScreen then
            video.translation = [1200,0]
            video.width = 720
            video.height = 405
            video.enableUI = false
        end if
        m.nodes.Labels.ChannelCount.text = "Cargando canal: 0%"
        video.content = item
        video.control = "play"
        m.currentlyPlayingItem = item
        m.nodes.FadeOutPreview.control = "start"
        m.errorState = false
        m.minBufferReached = false ' Reiniciar bandera para controlar el buffering mínimo
        m.forcePlayTimer.control = "start" ' Iniciar temporizador para forzar reproducción
    end if
end sub

sub setFullScreen(state)
    m.state.isFullScreen = state
    nodes = m.nodes
    nodes.RowList.visible = not state
    nodes.Labels.Category.visible = not state
    nodes.Labels.Category2.visible = not state
    nodes.Labels.ChannelCount.visible = not state
    nodes.InfoBar.visible = not state
    nodes.Menu.visible = not state
    
    if not state and nodes.Video.state <> "playing" then
        nodes.PreviewPoster.visible = true
        nodes.FadeInPreview.control = "start"
    else if state
        nodes.FadeOutPreview.control = "start"
    else
        nodes.FadeOutPreview.control = "start"
    end if
    
    if state then 
        nodes.Video.setFocus(true)
    else 
        nodes.RowList.setFocus(true)
        nodes.Video.translation = [1200,0]
        nodes.Video.width = 720
        nodes.Video.height = 405
        nodes.Video.enableUI = false
    end if
end sub

function onKeyEvent(key, press) as boolean
    if not press then return false
    if m.state.isFullScreen then
        video = m.nodes.Video
        if key = "back" then
            video.translation = [1200,0]
            video.width = 720
            video.height = 405
            video.enableUI = false
            setFullScreen(false)
            return true
        end if
        if key = "play" or key = "pause" then video.control = "pause": return true
        if key = "fastforward" then video.seek = video.position + 10: return true
        if key = "rewind" then video.seek = video.position - 10: return true
        return true
    end if
    
    if m.state.menuFocused then
        itemsCount = m.nodes.MenuItems.getChildCount() - 1
        if key = "right" or key = "back" then
            m.state.menuFocused = false
            m.nodes.RowList.setFocus(true)
            m.nodes.CollapseMenu.control = "start"
            hideMenuLabels()
            return true
        end if
        if key = "up" and m.state.menuItem > 0 then
            m.state.menuItem--
            updateMenuFocus()
            return true
        end if
        if key = "down" and m.state.menuItem < itemsCount then
            m.state.menuItem++
            updateMenuFocus()
            return true
        end if
        if key = "OK" then
            selectMenuItem()
            return true
        end if
    else
        if key = "left" then
            m.state.menuFocused = true
            m.nodes.Menu.setFocus(true)
            m.nodes.ExpandMenu.control = "start"
            updateMenuFocus()
            return true
        end if
        if key = "OK" then 
            ChannelChange()
            return true
        end if
        if key = "back" then
            ' Si el video está reproduciendo en segundo plano y la barra lateral no está abierta,
            ' abrir pantalla completa
            if m.nodes.Video.state = "playing" and not m.state.isFullScreen and not m.state.menuFocused then
                m.nodes.Video.translation = [0,0]
                m.nodes.Video.width = 1920
                m.nodes.Video.height = 1080
                m.nodes.Video.enableUI = true
                setFullScreen(true)
                return true
            end if
            return true
        end if
    end if
    return false
end function

sub updateMenuFocus()
    for i = 0 to m.nodes.MenuItems.getChildCount() - 1
        item = m.nodes.MenuItems.getChild(i)
        label = item.findNode("MenuLabel" + i.toStr())
        icon = item.findNode("IconHighlight" + i.toStr())
        label.visible = true
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
    for i = 0 to m.nodes.MenuItems.getChildCount() - 1
        item = m.nodes.MenuItems.getChild(i)
        item.findNode("MenuLabel" + i.toStr()).visible = false
        item.findNode("IconHighlight" + i.toStr()).visible = false
    end for
end sub

sub selectMenuItem()
    m.state.menuFocused = false
    m.nodes.CollapseMenu.control = "start"
    hideMenuLabels()
    
    if m.state.menuItem = 0 then
        m.nodes.RowList.setFocus(true)
    else
        kb = createObject("roSGNode", "KeyboardDialog")
        if kb = invalid then return
        kb.backgroundUri = "pkg:/images/FONDO.PNG"
        if m.state.menuItem = 1 then
            kb.title = "Buscar contenido"
            kb.text = ""
            kb.buttons = ["Buscar", "Cancelar"]
            kb.observeField("buttonSelected", "onSearchButtonPressed")
        else
            kb.title = "Cambiar URL del M3U"
            kb.text = m.global.lastUrl
            kb.buttons = ["Cargar", "Cancelar", "Restaurar URL original"]
            kb.observeField("buttonSelected", "onUrlButtonPressed")
        end if
        m.top.dialog = kb
    end if
end sub

sub onSearchButtonPressed()
    kb = m.top.dialog
    if kb = invalid then print "ERROR: KeyboardDialog inválido en búsqueda": return
    if kb.buttonSelected = 0 and kb.text <> "" then
        filterContent(kb.text)
    end if
    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub onUrlButtonPressed()
    kb = m.top.dialog
    if kb = invalid then print "ERROR: KeyboardDialog inválido en URL": return
    if kb.buttonSelected = 0 and kb.text <> "" then
        saveRecentUrl(kb.text)
        m.nodes.Labels.ChannelCount.text = "Cargando canales: 0%"
        m.global.lastUrl = kb.text
        m.LoadTask.control = "STOP"
        m.LoadTask.m3uUrl = kb.text
        m.LoadTask.control = "RUN"
        m.nodes.Labels.Category.text = "Cargando..."
        m.nodes.Labels.Category2.text = "Cargando..."
        m.nodes.LoadingAnim1.control = "start"
        m.nodes.LoadingAnim2.control = "start"
        m.content.removeChildrenIndex(m.content.getChildCount(), 0)
        for i = 0 to 1
            cat = createObject("roSGNode", "ContentNode")
            cat.title = "Cargando..."
            for j = 0 to 19
                item = createObject("roSGNode", "ContentNode")
                item.addField("isLoading", "boolean", true)
                item.isLoading = true
                cat.appendChild(item)
            end for
            m.content.appendChild(cat)
        end for
        m.nodes.RowList.content = m.content
        m.isLoadingList = true
        m.loadingProgress = 0
        m.loadingTimer.control = "start"
    else if kb.buttonSelected = 2 then
        saveRecentUrl(m.originalUrl)
        m.nodes.Labels.ChannelCount.text = "Cargando canales: 0%"
        m.global.lastUrl = m.originalUrl
        m.LoadTask.control = "STOP"
        m.LoadTask.m3uUrl = m.originalUrl
        m.LoadTask.control = "RUN"
        m.nodes.Labels.Category.text = "Cargando..."
        m.nodes.Labels.Category2.text = "Cargando..."
        m.nodes.LoadingAnim1.control = "start"
        m.nodes.LoadingAnim2.control = "start"
        m.content.removeChildrenIndex(m.content.getChildCount(), 0)
        for i = 0 to 1
            cat = createObject("roSGNode", "ContentNode")
            cat.title = "Cargando..."
            for j = 0 to 19
                item = createObject("roSGNode", "ContentNode")
                item.addField("isLoading", "boolean", true)
                item.isLoading = true
                cat.appendChild(item)
            end for
            m.content.appendChild(cat)
        end for
        m.nodes.RowList.content = m.content
        m.isLoadingList = true
        m.loadingProgress = 0
        m.loadingTimer.control = "start"
    end if
    m.top.dialog = invalid
    m.nodes.RowList.setFocus(true)
end sub

sub rowListContentChanged()
    channels = 0
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)
    for each cat in m.LoadTask.content.getChildren(-1, 0)
        categoryClone = cat.clone(true)
        for each item in categoryClone.getChildren(-1, 0)
            item.addField("isLoading", "boolean", true)
            item.isLoading = false
        end for
        m.content.appendChild(categoryClone)
        channels += categoryClone.getChildCount()
    end for
    m.nodes.RowList.content = m.content
    m.totalChannels = channels
    m.nodes.Labels.ChannelCount.text = "Canales cargados: " + channels.toStr()
    m.nodes.LoadingAnim1.control = "stop"
    m.nodes.LoadingAnim2.control = "stop"
    m.nodes.Labels.Category.opacity = 1.0
    m.nodes.Labels.Category2.opacity = 1.0
    m.isLoadingList = false
    m.loadingTimer.control = "stop"
    if m.content.getChildCount() > 0 then
        m.nodes.Labels.Category.text = m.content.getChild(0).title
        if m.content.getChildCount() > 1 then
            m.nodes.Labels.Category2.text = m.content.getChild(1).title
        else
            m.nodes.Labels.Category2.text = ""
        end if
    else
        m.nodes.Labels.Category.text = ""
        m.nodes.Labels.Category2.text = ""
    end if
    print "Contenido cargado: "; channels; " canales en "; m.content.getChildCount(); " categorías"
end sub

sub restoreChannelCount()
    if not m.errorState then
        m.nodes.Labels.ChannelCount.text = "Canales cargados: " + m.totalChannels.toStr()
    end if
end sub

sub onVideoStateChange()
    state = m.nodes.Video.state
    print "Video state changed to: "; state
    if state = "buffering" then
        m.nodes.Labels.ChannelCount.text = "Cargando canal: 0%"
    else if state = "playing" then
        m.nodes.Labels.ChannelCount.text = "Canal cargado"
        m.nodes.FadeOutPreview.control = "start"
        m.nodes.Timer.control = "start"
        m.errorState = false
        m.minBufferReached = true ' Buffering mínimo alcanzado, permitir reproducción continua
        m.forcePlayTimer.control = "stop" ' Detener el temporizador de forzar reproducción
    else if state = "error" then
        m.nodes.Labels.ChannelCount.text = "Link no funciona"
        if not m.state.isFullScreen then
            m.nodes.PreviewPoster.visible = true
            m.nodes.FadeInPreview.control = "start"
        end if
        m.errorState = true
        m.errorResetTimer.control = "start"
        m.forcePlayTimer.control = "stop" ' Detener el temporizador si hay un error
    else if state = "stopped" or state = "finished" then
        if m.errorState then
            m.nodes.Labels.ChannelCount.text = "Link no funciona"
        else
            m.nodes.Labels.ChannelCount.text = "Canales cargados: " + m.totalChannels.toStr()
            if not m.state.isFullScreen then
                m.nodes.PreviewPoster.visible = true
                m.nodes.FadeInPreview.control = "start"
            end if
        end if
        m.forcePlayTimer.control = "stop" ' Detener el temporizador si el video se detiene
    end if
    if not m.state.isFullScreen then
        m.nodes.Video.translation = [1200,0]
        m.nodes.Video.width = 720
        m.nodes.Video.height = 405
        m.nodes.Video.enableUI = false
    end if
end sub

sub onBufferingStatusChange()
    status = m.nodes.Video.bufferingStatus
    if status <> invalid and status.percentage <> invalid and m.nodes.Video.state = "buffering" then
        m.nodes.Labels.ChannelCount.text = "Cargando canal: " + status.percentage.toStr() + "%"
        ' Iniciar reproducción cuando se alcance un 5% de buffering para un inicio más rápido
        if status.percentage >= 5 and not m.minBufferReached then
            m.nodes.Video.control = "play"
            m.minBufferReached = true
            m.forcePlayTimer.control = "stop" ' Detener el temporizador si se alcanza el porcentaje
        end if
    end if
end sub

sub forcePlayVideo()
    if m.nodes.Video.state = "buffering" and not m.minBufferReached then
        print "Forzando reproducción después de 3 segundos de buffering"
        m.nodes.Video.control = "play"
        m.minBufferReached = true
    end if
end sub

sub resetErrorState()
    m.errorState = false
    if m.nodes.Video.state = "stopped" or m.nodes.Video.state = "finished" then
        m.nodes.Labels.ChannelCount.text = "Canales cargados: " + m.totalChannels.toStr()
    end if
end sub

sub filterContent(term)
    m.content.removeChildrenIndex(m.content.getChildCount(), 0)
    searchRow = createObject("roSGNode", "ContentNode")
    searchRow.title = "Búsqueda: " + term
    termLower = lcase(term)
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
    if searchRow.getChildCount() > 0 then m.content.appendChild(searchRow)
    for each cat in m.LoadTask.content.getChildren(-1, 0)
        categoryClone = cat.clone(true)
        for each item in categoryClone.getChildren(-1, 0)
            item.addField("isLoading", "boolean", true)
            item.isLoading = false
        end for
        m.content.appendChild(categoryClone)
    end for
    m.nodes.RowList.content = m.content
    count = searchRow.getChildCount()
    if count > 0 then
        m.nodes.Labels.ChannelCount.text = "Resultados: " + count.toStr()
        m.nodes.RowList.jumpToRowItem = [0, 0]
        updateCategoryLabel(0)
    else
        m.nodes.Labels.ChannelCount.text = "No se encontraron resultados"
        m.nodes.Labels.Category.text = ""
        m.nodes.Labels.Category2.text = ""
    end if
    print "Filtro aplicado: "; count; " resultados para "; term
end sub

function loadRecentUrls() as object
    registry = createObject("roRegistrySection", "RecentM3UUrls")
    urls = []
    for i = 1 to 3
        key = "url" + i.toStr()
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
    newUrls = []
    found = false
    for each u in m.recentUrls
        if u = url then
            found = true
        else
            newUrls.push(u)
        end if
    end for
    
    newUrls.unshift(url)
    if newUrls.count() > 3 then
        newUrls = newUrls.slice(0, 3)
    end if
    m.recentUrls = newUrls
    
    registry = createObject("roRegistrySection", "RecentM3UUrls")
    for i = 0 to m.recentUrls.count() - 1
        key = "url" + (i + 1).toStr()
        registry.write(key, m.recentUrls[i])
    end for
    registry.flush()
end sub
