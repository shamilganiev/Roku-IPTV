Sub Init()
    m.top.functionName = "load"
    print "M3U init"
End Sub

Sub load()
    url = m.top.m3uUrl
    if url = "" then url = "https://raw.githubusercontent.com/Tecnotuto/LTV/refs/heads/main/13DEMARZOONLINELATINOTVTECNOTUTO/13-03-2025"
    print "Cargando: " + url
    
    req = CreateObject("roUrlTransfer")
    if req=invalid then print "ERROR: No se pudo crear roUrlTransfer":return
    req.SetUrl(url)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.EnableFreshConnection(true)
    
    ' Intentar descargar con GetToFile primero
    tmpFile = "tmp:/downloaded.m3u"
    print "Descargando a: ";tmpFile
    port = CreateObject("roMessagePort")
    req.SetPort(port)
    if req.AsyncGetToFile(tmpFile)
        msg = wait(30000, port) ' Timeout de 30 segundos
        if msg <> invalid and type(msg) = "roUrlEvent"
            code = msg.GetResponseCode()
            print "GetToFile HTTP: ";code
            if code = 200
                fs = CreateObject("roFileSystem")
                if fs.Exists(tmpFile)
                    response = ReadAsciiFile(tmpFile)
                    fs.Delete(tmpFile)
                    if response = invalid or response = "" then
                        print "ERROR: Archivo descargado vacío o no legible"
                        return
                    end if
                else
                    print "ERROR: El archivo no se descargó correctamente"
                    return
                end if
            else
                print "ERROR: Fallo en GetToFile con HTTP ";code
                response = tryAsyncGetToString(req, url)
            end if
        else
            print "ERROR: Timeout o evento inválido en GetToFile"
            response = tryAsyncGetToString(req, url)
        end if
    else
        print "ERROR: Fallo al iniciar AsyncGetToFile"
        response = tryAsyncGetToString(req, url)
    end if
    
    if response = "" then print "ERROR: No se obtuvo respuesta":return
    print "Parseando archivo, longitud: ";response.len()
    list = parse(response)
    
    if list.count() = 0 then print "ERROR: Lista vacía":return
    m.top.content = toContentNode(list)
    print "Cargado: ";list.count();" categorías"
End Sub

Function tryAsyncGetToString(req as object, url as string) as string
    print "Intentando con AsyncGetToString..."
    req.SetUrl(url)
    port = CreateObject("roMessagePort")
    req.SetPort(port)
    if not req.AsyncGetToString() then
        print "ERROR: Fallo al iniciar AsyncGetToString"
        return ""
    end if
    msg = wait(30000, port)
    if msg <> invalid and type(msg) = "roUrlEvent"
        code = msg.GetResponseCode()
        print "AsyncGetToString HTTP: ";code
        if code = 200
            response = msg.GetString()
            if response <> "" then return response
            print "ERROR: Respuesta vacía en AsyncGetToString"
        else
            print "ERROR: Fallo en AsyncGetToString con HTTP ";code
        end if
    else
        print "ERROR: Timeout o evento inválido en AsyncGetToString"
    end if
    return ""
End Function

Function parse(m3u as string) as object
    lines = m3u.Split(Chr(10))
    if lines.count() < 2 then return []
    cats = {}
    i = 0
    while i < lines.count() - 1
        line = lines[i].Trim()
        if line.Left(7) = "#EXTINF"
            url = lines[i + 1].Trim()
            if url <> "" and url.Left(1) <> "#"
                cat = "Sin categoría"
                title = line.Mid(line.Instr(",") + 1).Trim()
                logo = ""
                gm = CreateObject("roRegex", "group-title=""([^""]+)""", "i").Match(line)
                if gm.count() > 1 then cat = gm[1]
                lm = CreateObject("roRegex", "tvg-logo=""([^""]+)""", "i").Match(line)
                if lm.count() > 1 then logo = lm[1]
                fmt = "hls"
                live = true
                if url.Right(4) = ".mp4"
                    fmt = "mp4"
                    live = false
                else if url.Right(4) = ".mkv"
                    fmt = "mkv"
                    live = false
                else if url.Right(4) = ".mov"
                    fmt = "mov"
                    live = false
                else if url.Right(3) = ".ts"
                    fmt = "ts"
                    live = true
                end if
                if not cats.DoesExist(cat) then cats[cat] = []
                cats[cat].Push({Title: title, HDPosterUrl: logo, Url: url, streamFormat: fmt, Live: live})
            end if
        end if
        i += 1
        if i mod 1000 = 0 then print "Procesadas ";i;" líneas"
    end while
    
    list = []
    for each c in cats
        list.Push({Title: c, ContentList: cats[c]})
    end for
    return list
End Function

Function toContentNode(list as object) as object
    rows = CreateObject("roSGNode", "ContentNode")
    for each r in list
        row = CreateObject("roSGNode", "ContentNode")
        row.Title = r.Title
        for each i in r.ContentList
            item = CreateObject("roSGNode", "ContentNode")
            item.SetFields(i)
            row.appendChild(item)
        end for
        rows.appendChild(row)
    end for
    return rows
End Function
