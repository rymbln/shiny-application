#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)

library(tidyverse)

library(ggplot2)
library(ggrepel)

library(plotly)

library(leaflet)
library(scales)

library(htmltools)

library(kableExtra)
library(flextable)
library(gt)

library(reactable)

library(rmarkdown)

library(openxlsx)

#### Определяем сайдбар ####
sidebar <- sidebar(
  # Устанавливаем ширину сайдбара
  width = 350,
  # Выбор файла для загрузки
  fileInput("fileInputCsv", accept = ".csv",
            label = "Загрузите таблицу",
            buttonLabel = "Выберите CSV",
            placeholder = "Файл не загружен" ),
  # Выбор группы пациентов
  selectInput(inputId = 'selPatgroup', label = 'Группа пациентов',
              choices = c(Все = '.'), selected = "."),
  # Выбор города
  selectInput('selCity', 'Город', choices = c(Все = '.'), selected = c("."),
              multiple = TRUE),
  # Выбор даты
  dateRangeInput('selDateRange','Дата взятия образца',
                 start = Sys.Date(), end = Sys.Date(), min = Sys.Date(), max = Sys.Date(),
                 format = "yyyy-mm-dd", startview = "month",
                 weekstart = 1, language = "ru", separator = " - ",
                 width = NULL, autoclose = TRUE),
  # Выбор возраста
  sliderInput('selAge', 'Возраст',
              min = 0, max = 120,       # Задайте максимальный возможный диапазон
              value = c(0, 120),        # Начальное положение
              step = 1, dragRange = TRUE),
  # Количество образцов
  p(textOutput("data_count")),
  # Количество центров
  p(textOutput("center_count"))
)

#### Определяем левый столбец инфографики ####

##### Количество пациентов в группах #####
info_numbers <- layout_columns(
  value_box(
    title = "Мужчины", fill = TRUE,
    value = textOutput("male_count"),
    showcase = bs_icon("person-standing"),
    showcase_layout = "top right",
    theme = "blue"
  ),
  value_box(
    title = "Женщины", fill = TRUE,
    value = textOutput("female_count"),
    showcase = bs_icon("person-standing-dress"),
    showcase_layout = "top right",
    theme = "purple"
  ),
  value_box(
    title = "Дети",  fill = TRUE,
    value = textOutput("children_count"),
    showcase = bs_icon("person-circle"),
    showcase_layout = "top right",
    theme = "orange"
  )
)

##### Выделенные организмы #####
info_org <-  layout_columns(
  card(full_screen = TRUE, plotOutput("plot_org_male")),
  card(full_screen = TRUE, plotOutput("plot_org_female")),
  card(full_screen = TRUE, plotOutput("plot_org_children"))
)

##### Диагнозы #####
info_diag <- card(full_screen = TRUE,
                  card_header("Структура диагнозов по группам пациентов"),
                  card_body(plotlyOutput("plot_diag"))
)

info_left <-  layout_columns(fill = TRUE,
                             # Ширина столбцов
                             col_widths = c(12, 12, 12),
                             # Высота строк в относительных единицах
                             row_heights = c(1,2,4),
                             info_numbers, # Строка 1 - Блоки с цифрами
                             info_org, # Строка 2 - Графики с организмами
                             info_diag # Строка 3 -График с диагнозами
)

#### Определяем правый столбец инфографики ####

##### Карта #####
info_map <- card(full_screen = TRUE,
                 card_header("Количество пациентов по городам"),
                 card_body(leafletOutput("map")))

##### Таблица с городами #####
info_map_table <- navset_card_tab(
  full_screen = TRUE,
  title = "Распределение пациентов по городам",
  nav_panel("kable", tableOutput("citypat_kb")),
  nav_panel("gt", gt_output("citypat_gt")),
  nav_panel("flextable", tableOutput("citypat_ft"))
)

info_right <-   layout_columns(fill = TRUE,
                               # Ширина столбцов
                               col_widths = c(12, 12),
                               # Высота строк
                               row_heights = c(1, 1),
                               info_map, # Строка 1 - Карта
                               info_map_table # Строка 2 - Таблица
)

#### Определяем интерфейс приложения ####
ui <- page_navbar(
  # Заголовок страницы
  title = "Shiny Дашборд",
  # Тема оформления приложения
  theme = bs_theme(bootswatch = "cosmo", 
                   # Настраиваем внешний вид range-слайдера
                   "--bs-form-range-track-height" = "8px",      # Высота трека
                   "--bs-form-range-track-bg" = "#dee2e6",      # Цвет трека
                   "--bs-form-range-thumb-width" = "22px",      # Ширина ручки
                   "--bs-form-range-thumb-height" = "22px",     # Высота ручки
                   "--bs-form-range-thumb-bg" = "#0d6efd",      # Цвет ручки
                   "--bs-form-range-thumb-border" = "2px solid #ffffff"
                   ),
  # Сайдбар с виджетами фильтрации
  sidebar = sidebar,
  # Первая страница с инфографикой
  nav_panel("Дашборд",
            # Страница
            page_fillable(
              # Столбцы в рамках страницы
              layout_columns(
                info_left, # Первый столбец - количество, организмы, диагнозы
                info_right # Второй столбец - карта, распределение по городам
              )
            )
  ),
  # Вторая страница с таблицей
  nav_panel("Набор данных", reactableOutput("data_rt")),
  # Заполняет свободное место
  nav_spacer(),
  # Кнопка скачивания
  nav_item(downloadButton(outputId = "downloadButton", label = "Скачать таблицу", icon = icon("download"), class = "btn-primary")),
  # Кнопка скачивания с проверкой
  nav_item(actionButton("downloadActionButton", "Скачать таблицу с проверкой")),
  # Кнопка генерации и скачивания отчета
  nav_item(downloadButton(outputId = "generateButton", label = "Создать отчет"))
)

#### Определяем логику приложения ####
server <- function(input, output, session) {
  #### Создание набора данных из загруженного файла ####
  dataset <- reactive({
    # Получаем файл
    file <- input$fileInputCsv
    # Получаем расширение файла
    ext <- tools::file_ext(file$datapath)
    # Проверяем, что файл действительно был выбран
    req(file)
    # Проверяем, что файл действительно csv
    validate(need(ext == "csv", "Пожалуйста, загрузите CSV-файл"))
    # Читаем содержимое файла
    dataset <- read.csv2(file$datapath, dec = ".")
    dataset$DATESTRAIN <- as.Date(dataset$DATESTRAIN)
    dataset$DATEBIRTH <- as.Date(dataset$DATEBIRTH)
    dataset$DATEFILL <- as.Date(dataset$DATEFILL)
    # Возвращаем результат чтения
    dataset
  })
  
  #### Обновление виджетов подписки ####
  observe({
    # Ждём загрузки данных
    req(dataset())  
    # Проверка, что набор данных не пустой
    if (!is.null(dataset())) {
      # Обновляем фильтр группы пациентов
      updateSelectInput(session, "selPatgroup",
                        choices = c(Все = ".",  sort(unique(dataset()$PAT_GROUP))),
                        selected = ".")
      # Обновляем фильтр городов
      updateSelectInput(session, "selCity",
                        choices = c(Все = ".",  sort(unique(dataset()$CITYNAME))),
                        selected = ".")
      # Обновляем фильтр дат
      updateDateRangeInput(session, 'selDateRange',
                           start = min(dataset()$DATESTRAIN, na.rm = TRUE),
                           end = max(dataset()$DATESTRAIN, na.rm = TRUE),
                           min = min(dataset()$DATESTRAIN, na.rm = TRUE),
                           max = max(dataset()$DATESTRAIN, na.rm = TRUE)
      )
      # Обновляем фильтр возраста
      updateSliderInput(session, 'selAge',
                        min = min(dataset()$AGE, na.rm = TRUE),
                        max = max(dataset()$AGE, na.rm = TRUE),
                        value = c(min(dataset()$AGE, na.rm = TRUE), max(dataset()$AGE, na.rm = TRUE))
      )
    }
  })
  
  #### Отбор данных по фильтрам ####
  data <- reactive({
    # Проверяем, что у нас есть данные из прочитанного файла
    if (is.null(dataset())) return(NULL);
    # Копируем исходный набор
    data <- dataset()
    # Фильтруем по группе пациентов
    if (input$selPatgroup != "." ) {
      data <- data %>% filter(PAT_GROUP == input$selPatgroup)
    }
    # Фильтруем по городам
    if ( !("." %in% input$selCity ) ) {
      data <- data %>% filter(CITYNAME %in% input$selCity)
    }
    # Фильтруем по дате
    if (length(input$selDateRange) == 2) {
      data <- data %>% filter(DATESTRAIN >= input$selDateRange[1] & DATESTRAIN <= input$selDateRange[2])
    }
    # Фильтруем по возрасту
    if (length(input$selAge) == 2) {
      data <- data %>% filter(AGE >= input$selAge[1] & AGE <= input$selAge[2])
    }
    # Возвращаем результат
    data
  })
  
  #### Расчет количества образцов ####
  output$data_count <- renderText({
    value <- 0
    if (!is.null(data())) {
      value <-  nrow(data())
    }
    paste('Выбрано', value, 'образцов', sep = ' ')
  })
  
  
  #### Расчет количества центров ####
  output$center_count <- renderText({
    value <- 0
    if (!is.null(data())) {
      value <- length(unique(data()$CENTER))
    }
    paste('Выбрано', value, 'центров', sep = ' ')
  })
  
  #### Расчет групп по полу ####
  # Количество мужчин
  output$male_count <- reactive({
    data() %>% filter(grepl("Мужчины",PAT_GROUP)) %>% nrow()
  })
  # Количество женщин
  output$female_count <- reactive({
    data() %>% filter(grepl("Женщины",PAT_GROUP)) %>% nrow()
  })
  # Количество детей
  output$children_count <- reactive({
    data() %>% filter(grepl("Дети",PAT_GROUP)) %>% nrow()
  })
  
  #### Расчет организмам по группам ####
  # Функция для фильтрации данных по группам
  org_filter <- function(data, group_name) {
    data() %>%
      filter(grepl(group_name,PAT_GROUP)) %>%
      group_by(STRAIN) %>%
      summarise(Count = n()) %>%
      ungroup() %>%
      mutate(Percent = round(100 * Count / sum(Count))) %>%
      arrange(desc(Percent)) %>%
      mutate(csum = rev(cumsum(rev(Count))),
             pos = Count/2 + lead(csum, 1),
             pos = if_else(is.na(pos), Count/2, pos))
  }
  # Функция для отрисовки графика ggplot2
  org_plot <- function(data) {
    ggplot(data, aes(x = "" , y = Count, fill = fct_inorder(STRAIN))) +
      geom_col(width = 1, color = 1) +
      coord_polar(theta = "y") +
      scale_fill_brewer(palette = "Pastel1") +
      geom_label_repel(data = data,
                       aes(y = pos, label = paste0(Count, " (", Percent, "%)")),
                       size = 4.5, nudge_x = 1, show.legend = FALSE) +
      guides(fill = guide_legend(title = "Организм")) +
      theme_void()
  }
  
  # Организмы у мужчин
  output$plot_org_male <- renderPlot({
    org_male <- org_filter(data(), "Мужчины")
    validate(need(nrow(org_male) > 0, "Данные отсутствуют"))
    org_plot(org_male)
  })
  
  # Организмы у женщин
  output$plot_org_female <- renderPlot({
    org_female <- org_filter(data(), "Женщины")
    validate(need(nrow(org_female) > 0, "Данные отсутствуют"))
    org_plot(org_female)
  })
  
  # Организмы у детей
  output$plot_org_children <- renderPlot({
    org_children <- org_filter(data(), "Дети")
    validate(need(nrow(org_children) > 0, "Данные отсутствуют"))
    org_plot(org_children)
  })
  
  #### Расчет диагнозов по группам ####
  output$plot_diag <- renderPlotly({
    # Формируем нужные наборы данных
    diag <- data() %>% group_by(PAT_GROUP, mkb_name) %>%
      summarise(Count = n()) %>%
      ungroup() %>%
      pivot_wider(names_from = "PAT_GROUP", values_from = "Count", values_fill = 0) %>%
      mutate(mkb_name = case_when(
        mkb_name == "Интерстициальный цистит (хронический)" ~ "Хронический цистит",
        mkb_name == "Необструктивный хронический пиелонефрит, связанный с рефлюксом" ~ "Хронический пиелонефрит",
        mkb_name == "Острый тубулоинтерстициальный нефрит" ~ "Острый нефрит",
        mkb_name == "Инфекция мочевыводящих путей без установленной локализации" ~ "Инфекция МВП",
        TRUE ~ mkb_name
      ))
    # Проверяем наличие данных
    validate(
      need(nrow(diag) > 0, "Данные отсутствуют")
    )
    # Определение заранее возможные категории
    categories <- c(
      'Дети, неосложненные', 'Дети, осложненные',
      'Женщины, неосложненные', 'Женщины, осложненные',
      'Мужчины, неосложненные', 'Мужчины, осложненные'
    )
    # Добавление недостающих столбцов для упрощенного построения графика
    diag_plot <- diag
    for (i in seq_along(categories)) {
      category <- categories[i]
      if (!(category %in% colnames(diag_plot))) {
        diag_plot[[category]] <- 0
      }
    }
    # Построение графика
    plot_ly(data = diag_plot, x = ~mkb_name, type = 'bar',
            y = ~`Дети, неосложненные`, name = 'Дети, неосложненные',
            marker = list(color = 'rgba(247,167,102, 0.8)')) %>%
      add_trace(y = ~`Дети, осложненные`, name = 'Дети, осложненные',
                marker = list(color = 'rgba(243,109,0, 0.8)')) %>%
      add_trace(y = ~`Женщины, неосложненные`, name = 'Женщины, неосложненные',
                marker = list(color = 'rgba(134,96,142, 0.8)')) %>%
      add_trace(y = ~`Женщины, осложненные`, name = 'Женщины, осложненные',
                marker = list(color = 'rgba(108,48,130, 0.8)')) %>%
      add_trace(y = ~`Мужчины, неосложненные`, name = 'Мужчины, неосложненные',
                marker = list(color = 'rgba(39,188,209, 0.8)')) %>%
      add_trace(y = ~`Мужчины, осложненные`, name = 'Мужчины, осложненные',
                marker = list(color = 'rgba(36,107,206, 0.8)')) %>%
      layout(yaxis = list(title = 'Кол-во'), barmode = 'stack') %>%
      layout(xaxis = list(title = '' )) %>%
      layout(legend = list(orientation = 'h'))
  })
  
  #### Создание карты пациентов по городам ####
  output$map <- renderLeaflet({
    # Все пациенты
    all <- data() %>% select(CITYNAME, LATITUDE, LONGITUDE) %>%
      group_by(CITYNAME, LATITUDE, LONGITUDE) %>%
      summarise(Count = n()) %>%
      ungroup()
    # Мужчины
    men <- data() %>%
      filter(grepl("Мужчины",PAT_GROUP)) %>%
      select(CITYNAME, LATITUDE, LONGITUDE) %>%
      group_by(CITYNAME, LATITUDE, LONGITUDE) %>%
      summarise(CountMen = n()) %>%
      ungroup()
    # Женщины
    women <- data() %>%
      filter(grepl("Женщины",PAT_GROUP)) %>%
      select(CITYNAME, LATITUDE, LONGITUDE) %>%
      group_by(CITYNAME, LATITUDE, LONGITUDE) %>%
      summarise(CountWoman = n()) %>%
      ungroup()
    # Дети
    children <- data() %>%
      filter(grepl("Дети",PAT_GROUP)) %>%
      select(CITYNAME, LATITUDE, LONGITUDE) %>%
      group_by(CITYNAME, LATITUDE, LONGITUDE) %>%
      summarise(CountChild = n()) %>%
      ungroup()
    # Набор данных для отображения на карте
    mapdata <- all %>% left_join(men) %>% left_join(women) %>% left_join(children) %>%
      mutate_all(~replace(., is.na(.), 0))
    # Проверка наличия данных
    validate(need(nrow(mapdata) > 0, "Данные отсутствуют"))
    # Создание карты
    mapdata %>%
      leaflet() %>%
      addCircleMarkers(
        lng = ~ LONGITUDE,
        lat = ~ LATITUDE,
        stroke = FALSE,
        fillOpacity = 0.5,
        radius = ~ scales::rescale(sqrt(Count), c(1, 10)),
        label = ~ paste(
          "<strong>" , CITYNAME, ": ", Count,        "</strong>",
          "<br/>",
          "Мужчин:", CountMen, "<br/>",
          "Женщин:",  CountWoman, "<br/>",
          "Дети:",  CountChild
        ),
        labelOptions = c(textsize = "15px")) %>%
      addTiles("http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}")
  })
  
  #### Таблица с пациентами по городам ####
  citypat <- reactive({
    citypat <- data() %>%
      group_by(CITYNAME, PAT_GROUP) %>% summarise(Count = n()) %>%
      ungroup() %>%
      pivot_wider(names_from = "PAT_GROUP", values_from = "Count", values_fill = 0) %>%
      select(order(colnames(.)))
    
    colnames(citypat)[1] <- "Город"
    citypat
  })
  
  #### Таблица gt ####
  output$citypat_gt <- render_gt({
    # Проверка на отсутствие данных
    validate(need(nrow(citypat()) > 0, "Данные отсутствуют"))
    # Создание таблицы
    citypat() %>%
      gt() %>%
      tab_header(title = "Распределение пациентов по городам") %>%
      tab_spanner(label = "Дети", columns = starts_with("Дети")) %>%
      tab_spanner(label = "Женщины", columns = starts_with("Женщины")) %>%
      tab_spanner(label = "Мужчины", columns = starts_with("Мужчины")) %>%
      cols_label(
        ends_with(", неосложненные") ~ "Неосложненные",
        ends_with(", осложненные") ~ "Осложненные"
      ) %>%
      opt_row_striping()
  })
  
  #### Таблица flextable ####
  output$citypat_ft <- renderUI({
    # Проверка на отсутствие данных
    validate(need(nrow(citypat()) > 0, "Данные отсутствуют"))
    # Создание таблицы
    citypat() %>%
      flextable() %>%
      separate_header(split = ", ") %>%
      labelizor(part = "header",
                labels = c("diagnosis" = "Диагноз",
                           "sex" = "Пол",
                           "n" = "Случаев",
                           "percent" = "Процент",
                           "diag" = "в группе",
                           "overall" = "всего")) %>%
      set_caption("Распределение пациентов по городам") %>%
      theme_zebra() %>%
      htmltools_value()
  })
  
  #### Таблица kable ####
  output$citypat_kb <- function(){
    # Проверка на отсутствие данных
    validate(need(nrow(citypat()) > 0, "Данные отсутствуют"))
    # Создание таблицы
    citypat() %>%
      kbl(caption = "Распределение пациентов по городам") %>%
      kable_styling(bootstrap_options = c("striped"))
  }
  
  #### Таблица reactable ####
  # Локализованные подписи кнопок
  options(reactable.language = reactableLang(
    pageSizeOptions   = "показано {rows} значений",
    pageInfo          = "с {rowStart} по {rowEnd} из {rows} строк",
    pagePrevious      = "назад",
    pageNext          = "вперед",
    searchPlaceholder = "Поиск...",
    noData            = "Значения не найдены"
  ))
  # Создание таблицы
  output$data_rt <- renderReactable({
    # Проверка на отсутствие данных
    validate(need(nrow(data()) > 0, "Данные отсутствуют"))
    # Создание таблицы
    data() %>%
      # Исключение ненужных столбцов
      select(-c("LATITUDE", "LONGITUDE")) %>%
      # Выбор необходимых столбцов в нужном порядке
      select(study_subject_id, PAT_GROUP, SEX, AGE, DATEBIRTH,
             STRAIN, DATESTRAIN,
             CENTER, COUNTRY, CITYNAME, DATEFILL,
             DIAG_ICD, mkb_name, COMPL) %>%
      # Создание реактивной таблицы
      reactable(filterable = TRUE, searchable = TRUE, striped = TRUE,
                # Параметры отображения столбцов
                columns = list(
                  study_subject_id = colDef(name = "ID", width = 64, defaultSortOrder = "asc"),
                  PAT_GROUP = colDef(name = "Группа", width = 150),
                  SEX = colDef(name = "Пол", width = 100),
                  AGE = colDef(name = "Возраст", width = 90),
                  DATEBIRTH = colDef(name = "Дата рожд.", width = 120),
                  STRAIN = colDef(name = "Организм", width = 150),
                  DATESTRAIN = colDef(name = "Дата получ.", width = 120),
                  CENTER = colDef(name = "Центр", width = 70),
                  COUNTRY = colDef(name = "Страна", width = 100),
                  CITYNAME = colDef(name = "Город", width = 150),
                  DATEFILL = colDef(name = "Дата заполн.", width = 120),
                  DIAG_ICD = colDef(name = "МКБ-10", width = 80),
                  mkb_name = colDef(name = "Диагноз"),
                  COMPL = colDef(name = "Осложнения")
                ))
  })
  
  #### Скачивание таблицы ####
  output$downloadButton <- downloadHandler(
    # Имя скачиваемого файла
    filename = function() {
      "table.xlsx"
    },
    # Файл, который будет скачан
    content = function(file) {
      # Проверка на отсутствие данных
      validate(need(nrow(data()) > 0, "Данные отсутствуют"))
      # Создание таблицы
      write.xlsx(data(), file, asTable = TRUE)
    }
  )
  
  #### Скачивание таблицы с проверкой ####
  observeEvent(input$downloadActionButton, {
    # Если файл загружен
    if (!is.null(input$fileInputCsv)) {
      # Показываем диалог скачивания
      showModal(modalDialog(
        # Заголовок диалога
        title = "Скачать набор данных",
        # Сообщение внутри диалога
        p(paste("Набор данных включает", nrow(data()), "образцов", sep = " ")),
        footer = list(
          # Кнопка скачивания
          downloadButton(outputId = "downloadModalButton",
                         label = "Скачать"),
          # Кнопка закрытия диалога
          modalButton("Закрыть")
        )
      ))
    } else {
      # Если данные отсутствуют, показываем сообщение
      showModal(modalDialog(
        # Заголовок диалога
        title = "Данные отсутствуют",
        # Сообщение внутри диалога
        p("Загрузите файл или выберите другие значения фильтров"),
        # Кнопка закрытия диалога
        footer = list(modalButton("Закрыть"))
      ))
    }
  })
  
  #### Обработка скачивания из модального диалога ####
  output$downloadModalButton <- downloadHandler(
    # Имя скачиваемого файла
    filename = function() {
      "table.xlsx"
    },
    # Файл, который будет скачан
    content = function(file) {
      # Проверка на отсутствие данных
      validate(need(nrow(data()) > 0, "Данные отсутствуют"))
      # Создание таблицы
      write.xlsx(data(), file, asTable = TRUE)
    }
  )
  
  #### Запуск генерации отчета ####
  # Генерация отчета
  output$generateButton <-  downloadHandler(
    filename = "report.html",
    content = function(file) {
      # Отображение сообщения о выполняемых действиях
      id <- showNotification("Подготовка отчета...",
                             duration = NULL, closeButton = FALSE)
      # Когда работа функции закончится, убрать сообщение
      on.exit(removeNotification(id), add = TRUE)
      # Запуск процедуры
      render("report.Rmd", output_file = file,
             params = list(data = data()),
             envir = new.env(parent = globalenv()))
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)

