require 'benchmark'

def overwrite(text, lines_back = 1)
  erase_lines = "\033[1A\033[0K" * lines_back
  system("echo \"\r#{erase_lines}#{text}\"")
end

# Менеджер нагрузки. Отвечает за распределение нагрузки между задачами
class WorkerManger
  attr_reader :jobs

  MAX_THREADS = 3

  def initialize
    @workers = []
    @jobs = Queue.new
    @perform_queue = Queue.new
    @worker_queue_id = 0
    @active_threads = 0
    @is_free = false
    @semaphore = Mutex.new
  end

  def set_workers(workers)
    @workers.push(*workers)
  end

  def set_job(worker_id, job)
    @workers[worker_id].set_job(job)
    @perform_queue.push(@workers[worker_id])
  end

  def add_job(job)
    @jobs.push job
  end

  def get_job
    @jobs.pop
  end

  def notify(over=true)
    output = ''

    @workers.each do |worker|
      output << worker.to_s << "\n"
    end

    over ? overwrite(output, @workers.count + 1) : puts(output)
  end

  def get_worker
    @semaphore.synchronize do
      @perform_queue.pop
    end
  end

  # Запуск нового потока
  def run_thread
    tt = Thread.new do
      id = nil

      @semaphore.synchronize do
        @active_threads += 1
        id = @active_threads
      end

      until @perform_queue.empty? && @jobs.empty?
        current_worker = nil
        current_worker = get_worker

        current_worker&.setup(id)
        notify

        current_worker&.perform
        notify
      end

      @semaphore.synchronize do
        @active_threads -= 1
      end
      notify
    end

    tt.run
  end

  # Запуск менеджера нагрузки
  def run
    puts 'Main Thread RUN'
    notify(false)
    worker_id = 0

    bm = Benchmark.measure do
      until @jobs.empty? && @perform_queue.empty? && @active_threads.zero?
        unless @jobs.empty?
          job = @jobs.pop
          set_job(worker_id, job)

          worker_id = (worker_id + 1) % @workers.size
        end

        run_thread if @active_threads < MAX_THREADS

        sleep(0.1)
      end
    end

    puts "THE WORK IS DONE per #{bm.real}s"
    @is_free = true
  end
end

# Исполнитель задачи
class Worker
  attr_reader :id

  def initialize(id)
    @id = id
    @queue = Queue.new
    @job = nil
    @thread = nil
  end

  def set_job(job_id)
    @queue.push job_id
    job_id
  end

  def setup(thread_id)
    @thread = thread_id
    @job = @queue.pop
  end

  # Эмулируем работу на задаче
  def perform
    sleep(rand(5..15))

    on_success
  end

  def on_success
    @job = nil
    @thread = nil
  end

  def to_s
    worker_id = "Worker #{@id}".ljust(15)
    status = @job ? "RUNNING job #{@job}" : 'FREE'
    thread = @thread ? "thread #{@thread}" : ''

    worker_id + status.rjust(15) + thread.rjust(15)
  end

  class << self
    # Генерация необходимого числа исполнителей
    def create(num)
      res = []
      num.times do |i|
        res.push Worker.new(i + 1)
      end

      res
    end
  end
end

# Количество задач
JOBS_NUM = 10
# Количество исполнителей
WORKERS_NUM = 4

manager = WorkerManger.new

workers = Worker.create(WORKERS_NUM)
manager.set_workers(workers)

(1..JOBS_NUM).each { |job| manager.add_job job }

# Запуск менеджера нагрузки
manager.run
