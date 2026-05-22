# Пример приложения Shiny 

## Сборка образа docker

```bash
docker build -t demo-shiny-app .
```

## Публикация docker-образа на DockerHub

```bash
# Логинимся в DockerHub
docker login

# Собираем образ для репозитория в DockerHub
docker build -t rymbln/demo-shiny-app .

# Отправляем собранный образ на DockerHub
docker push rymbln/demo-shiny-app

# Запускаем образ из DockerHub
docker run -d --rm --name my-demo-shiny-app -p 3838:3838 rymbln/demo-shiny-app
```

## Запуск контейнера docker

```bash
docker run -d --rm --name my-demo-shiny-app -p 3838:3838 demo-shiny-app
```

## Запуск в docker-compose 

```bash 
# Остановить контейнеры
docker-compose down

# Остановить + удалить тома (осторожно: данные удалятся!)
docker-compose down -v

# Остановить + удалить образы
docker-compose down --rmi all
```