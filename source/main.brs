' ********** Copyright 2016 Roku Corp. All Rights Reserved. **********
' Based on Roku SceneGraph sample code.
' Modified by Shamil Ganiev.

sub Main()
    ' Create the main screen and message port
    ' Создать главный экран и порт сообщений
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Initialize global variables with error handling
    ' Инициализировать глобальные переменные с обработкой ошибок
    initializeGlobalVariables(screen)
    
    ' Detect the device model
    ' Определить модель устройства
    setDeviceModel()
    
    ' Initialize the main scene
    ' Инициализировать главную сцену
    initializeScene(screen)
    
    ' Run the main event loop
    ' Запустить главный цикл обработки событий
    runEventLoop()
end sub

sub initializeGlobalVariables(screen as Object)
    ' Configure the global node with default values
    ' Настроить глобальный узел со значениями по умолчанию
    m.global = screen.getGlobalNode()
    
    ' Define fields individually
    ' Определить поля по отдельности
    m.global.addField("Model", "integer", true)
    m.global.Model = 0
    m.global.addField("Options", "integer", true)
    m.global.Options = 2
end sub

sub setDeviceModel()
    ' Retrieve and validate device information
    ' Получить и проверить информацию об устройстве
    dev = CreateObject("roDeviceInfo")
    if dev <> invalid then
        modelString = dev.GetModel()
        if modelString <> invalid and Len(modelString) > 0 then
            modelNum = Left(modelString, 1).toInt()
            if modelNum < 4 then
                m.global.Model = 1
            end if
        end if
    end if
end sub

sub initializeScene(screen as Object)
    ' Create and configure the scene
    ' Создать и настроить сцену
    scene = screen.CreateScene("HomeScene")
    screen.show()
    
    ' Configure components with validation
    ' Настроить компоненты с проверкой
    m.RowList = scene.findNode("RowList")
    if m.RowList <> invalid then
        m.RowList.observeField("rowItemSelected", m.port)
    end if
    
    m.Video = scene.findNode("Video")
end sub

sub runEventLoop()
    ' Main event loop with improved event handling
    ' Главный цикл обработки событий с улучшенной обработкой событий
    while true
        msg = wait(0, m.port)
        if msg = invalid then
            ' Skip to the next iteration if the message is invalid
            ' Перейти к следующей итерации, если сообщение недействительно
        else
            msgType = type(msg)
            if msgType = "roSGScreenEvent" then
                if msg.isScreenClosed() then 
                    exit while
                end if
            else if msgType = "roSGNodeEvent" then
                handleNodeEvent(msg)
            end if
        end if
    end while
end sub

sub handleNodeEvent(msg as Object)
    ' Handle events from specific nodes
    ' Обработать события от определённых узлов
    node = msg.GetNode()
    field = msg.GetField()
    
    if node = "RowList" and field = "rowItemSelected" then
        ' Get the selected item index
        ' Получить индекс выбранного элемента
        index = msg.GetData()
        ' TODO: Add logic to handle the selected item
        ' TODO: Добавить логику обработки выбранного элемента
    end if
end sub
