function normalizeLanguageCode(languageCode as dynamic) as string
    if languageCode = invalid then return "ru"

    code = LCase(languageCode.toStr())

    if Len(code) >= 2 then
        code = Left(code, 2)
    end if

    if code = "en" or code = "es" or code = "ru" then
        return code
    end if

    return "ru"
end function

function loadLanguage(languageCode as dynamic) as object
    code = normalizeLanguageCode(languageCode)

    if code = "en" then
        return getEnStrings()
    else if code = "es" then
        return getEsStrings()
    end if

    return getRuStrings()
end function

function detectDeviceLanguage() as string
    deviceInfo = CreateObject("roDeviceInfo")

    if deviceInfo = invalid then
        return "ru"
    end if

    currentLocale = deviceInfo.GetCurrentLocale()

    if currentLocale = invalid or currentLocale = "" then
        return "ru"
    end if

    return normalizeLanguageCode(currentLocale)
end function

function loadSavedLanguage() as string
    registry = CreateObject("roRegistrySection", "Settings")

    if registry <> invalid and registry.Exists("language") then
        savedLanguage = registry.Read("language")

        if savedLanguage <> invalid and savedLanguage <> "" then
            return normalizeLanguageCode(savedLanguage)
        end if
    end if

    ' Use Russian by default until the language selector is implemented
    ' Использовать русский язык по умолчанию до добавления выбора языка
    return "ru"
end function

sub saveLanguage(languageCode as dynamic)
    code = normalizeLanguageCode(languageCode)
    registry = CreateObject("roRegistrySection", "Settings")

    if registry = invalid then return

    registry.Write("language", code)
    registry.Flush()
end sub

function getAvailableLanguages() as object
    return [
        {
            code: "ru"
            name: "Русский"
        }
        {
            code: "en"
            name: "English"
        }
        {
            code: "es"
            name: "Español"
        }
    ]
end function