# Менеджер распределения нагрузки между исполнителями
Позволяет использовать количество потоков меньше, чем количество исполнителей

### Настройка
`WorkerManger::MAX_THREADS` - количество потоков

`JOBS_NUM` - тестовое количество задач

`WORKERS_NUM` - тестовое количество исполнителей

### Запуск
Версия `ruby >= 3.1`
```
> ruby main.rb 
```

### Пример вывода
```
  Worker 1                  FREE               
  Worker 2         RUNNING job 2       thread 2
  Worker 3         RUNNING job 3       thread 3
  Worker 4         RUNNING job 4       thread 1
```
