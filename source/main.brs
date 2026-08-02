' ********** Copyright 2016 Roku Corp. All Rights Reserved. **********

sub Main()
    ' Crear pantalla principal y puerto de mensajes
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Configurar variables globales con manejo de errores
    initializeGlobalVariables(screen)
    
    ' Determinar tipo de modelo
    setDeviceModel()
    
    ' Inicializar escena principal
    initializeScene(screen)
    
    ' Bucle principal de eventos
    runEventLoop()
end sub

sub initializeGlobalVariables(screen as Object)
    ' Configurar nodo global con valores por defecto
    m.global = screen.getGlobalNode()
    
    ' Definir campos individualmente
    m.global.addField("Model", "integer", true)
    m.global.Model = 0
    m.global.addField("Options", "integer", true)
    m.global.Options = 2
end sub

sub setDeviceModel()
    ' Obtener y validar información del dispositivo
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
    ' Crear y configurar la escena
    scene = screen.CreateScene("HomeScene")
    screen.show()
    
    ' Configurar componentes con validación
    m.RowList = scene.findNode("RowList")
    if m.RowList <> invalid then
        m.RowList.observeField("rowItemSelected", m.port)
    end if
    
    m.Video = scene.findNode("Video")
end sub

sub runEventLoop()
    ' Bucle principal con mejor manejo de eventos
    while true
        msg = wait(0, m.port)
        if msg = invalid then
            ' Saltar al siguiente ciclo si el mensaje es inválido
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
    ' Manejar eventos de nodos específicos
    node = msg.GetNode()
    field = msg.GetField()
    
    if node = "RowList" and field = "rowItemSelected" then
        ' Manejar selección de elemento aquí
        index = msg.GetData()
        ' Agregar lógica para manejar la selección
    end if
end sub
