#Использовать strings
#Использовать v8runner
#Использовать tempfiles
#Использовать asserts
#Использовать tool1cd

Перем Лог;
Перем ВФ;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
    
    ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Выгрузка версии из хранилища в рабочую среду");
    Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "АдресХранилища", "Хранилище конфигурации 1С из которого выполняется сборка");
    // TODO с помощью tool1cd можно не применять авторизацию
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-storage-user", "Пользователь хранилища 1С");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-storage-pwd", "Пароль пользователя хранилища 1С (опционально)");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-storage-v", "Версия в хранилище, которую включаем в дистрибутив (опционально)");
    Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-use-tool1cd", "Использовать для чтения хранилища Tool1CD");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-details", "Выходной файл с параметрами коммита хранилища (только для tool1cd)");
    
    Парсер.ДобавитьКоманду(ОписаниеКоманды);
    
КонецПроцедуры

// Выполняет логику команды
//
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
    Параметры = РазобратьПараметры(ПараметрыКоманды);
    
    Попытка
        ФайлВерсии = ПолучитьИмяВременногоФайла(".cf");
        Если Параметры.ИспользоватьTool1CD Тогда
            ВыгрузитьВерсиюСредствамиTool1CD(Параметры.АдресХранилища, Параметры.ВерсияХранилища, ФайлВерсии);
        Иначе
            ВыгрузитьВерсиюИзХранилища(Параметры.АдресХранилища, Параметры.ВерсияХранилища, ФайлВерсии, Параметры.ПользовательХранилища, Параметры.ПарольХранилища);
        КонецЕсли;
        
        ФайлТест = Новый Файл(ФайлВерсии);
        Ожидаем.Что(ФайлТест.Существует(), "Должен существовать выгруженный файл версии");
        
        УправлениеКонфигуратором = ОкружениеСборки.ПолучитьКонфигуратор();
        ЗагрузитьКонфигурациюВБазуСборки(УправлениеКонфигуратором, ФайлВерсии);
    Исключение
        ВФ.Удалить();
        ВызватьИсключение;
    КонецПопытки;

    ВФ.Удалить();
    
КонецФункции

Процедура ЗагрузитьКонфигурациюВБазуСборки(Знач УправлениеКонфигуратором, Знач ФайлВерсии) Экспорт
    Лог.Информация("Загружаю версию во временную базу");
    УправлениеКонфигуратором.ЗагрузитьКонфигурациюИзФайла(ФайлВерсии, Истина);
    Лог.Информация(УправлениеКонфигуратором.ВыводКоманды());
КонецПроцедуры

// экспортная для целей тестирования
Функция РазобратьПараметры(Знач ПараметрыКоманды) Экспорт
    
    Результат = Новый Структура;
    
    Если ПустаяСтрока(ПараметрыКоманды["АдресХранилища"]) Тогда
        ВызватьИсключение "Не задан адрес хранилища";
    КонецЕсли;
    
    Результат.Вставить("АдресХранилища", ПараметрыКоманды["АдресХранилища"]);
    Результат.Вставить("ПользовательХранилища", ПараметрыКоманды["-storage-user"]);
    Результат.Вставить("ПарольХранилища", ПараметрыКоманды["-storage-pwd"]);
    Результат.Вставить("ВерсияХранилища", ПараметрыКоманды["-storage-v"]);
    Результат.Вставить("ИспользоватьTool1CD", ПараметрыКоманды["-use-tool1cd"]);
    Результат.Вставить("ФайлПараметровКоммита", ПараметрыКоманды["-details"]);
    
    Возврат Результат;
    
КонецФункции

Процедура ВыгрузитьВерсиюИзХранилища(Знач АдресХранилища,
    Знач ВерсияХранилища,
    Знач ВыходнойФайл,
    Знач ПользовательХранилища = Неопределено,
    Знач ПарольХранилища = Неопределено) Экспорт
    
    ВременныйКаталог = "";
    Конфигуратор = ПолучитьКонфигуратор(ВременныйКаталог);
    
    Лог.Отладка("Выгружаю версию из хранилища");
    
    Конфигуратор.ПолучитьВерсиюИзХранилища(
        АдресХранилища,
        ПользовательХранилища,
        ПарольХранилища,
        ВерсияХранилища);
        
    Лог.Отладка("Копирую файл версии");
    КопироватьФайл(ОбъединитьПути(ВременныйКаталог, "source.cf"), ВыходнойФайл);
    
    ВФ.Удалить();
    Лог.Отладка("Удален временный каталог: " + ВременныйКаталог);
КонецПроцедуры

Процедура ВыгрузитьВерсиюСредствамиTool1CD(Знач КаталогХранилища, Знач ВерсияХранилища, Знач ФайлВерсии) Экспорт
    
    ФайлХранилища = ОбъединитьПути(КаталогХранилища, "1cv8ddb.1CD");
    Чтение = Новый ЧтениеХранилищаКонфигурации;
    Если ВерсияХранилища = Неопределено Тогда
        ВерсияХранилища = 0;
    КонецЕсли;
    
	ВызватьИсключение "Не реализовано";

    Чтение.ВыгрузитьВерсиюКонфигурации(ФайлХранилища, ФайлВерсии, ВерсияХранилища);

КонецПроцедуры

Функция ПолучитьКонфигуратор(РабочийКаталог = "")
    
    Если ПустаяСтрока(РабочийКаталог) Тогда
        РабочийКаталог = ВФ.СоздатьКаталог();
        Лог.Отладка("Создан временный каталог: " + РабочийКаталог);
    КонецЕсли;
    
    Конфигуратор = Новый УправлениеКонфигуратором();
    Конфигуратор.КаталогСборки(РабочийКаталог);
    
    Возврат Конфигуратор;
    
КонецФункции // ПолучитьКонфигуратор()

//////////////////////////////////////////////////////////////////////////////

Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
ВФ = Новый МенеджерВременныхФайлов;