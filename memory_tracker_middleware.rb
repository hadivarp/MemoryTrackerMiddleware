require 'json'
require 'memory_profiler'
require 'sys/proctable'

class MemoryTrackerMiddleware
  def initialize(app, options = {})
    @app = app
    @threshold = options.fetch(:threshold, 10) # Memory growth threshold in MB
    @log_file = options.fetch(:log_file, Rails.root.join('log', 'memory_tracker.log'))
  end

  def call(env)
    request_id = extract_request_id_from_main_logs(env) || SecureRandom.uuid
    start_time = Time.now

    gc_stat_before, memory_before, objects_before, query_cache_before = capture_state
    status, headers, body = @app.call(env)
    gc_stat_after, memory_after, objects_after, query_cache_after = capture_state

    request_time = (Time.now - start_time).round(3)

    log_request(
      env,
      request_id,
      gc_stat_before,
      gc_stat_after,
      memory_before,
      memory_after,
      objects_before,
      objects_after,
      query_cache_before,
      query_cache_after,
      request_time,
      status
    )

    log_memory_threshold_exceeded(request_id, memory_after - memory_before) if memory_growth_exceeded?(memory_after, memory_before)

    [status, headers, body]
  end

  private

  def extract_request_id_from_main_logs(env)
    log_file_path = Rails.root.join('log', 'development.log')

    return unless File.exist?(log_file_path)

    # Read the last line from the development log file
    last_line = File.readlines(log_file_path).last

    # Extract the request ID from the last line
    request_id_match = last_line.match(/\[([\w-]+)\]/)
    request_id_match[1] if request_id_match
  end

  def capture_state
    gc_stats = GC.stat
    memory = process_memory
    object_counts = ObjectSpace.count_objects
    query_cache_size = ActiveRecord::Base.connection.query_cache.size

    [gc_stats, memory, object_counts, query_cache_size]
  end

  def process_memory
    pid = Process.pid
    process_info = Sys::ProcTable.ps.find { |p| p.pid == pid }
    process_info ? process_info.rss * 1024 : 0  # Convert RSS to bytes
  end

  def log_request(env, request_id, gc_stat_before, gc_stat_after, memory_before, memory_after, objects_before, objects_after, query_cache_before, query_cache_after, request_time, status)
    log_data = {
      request_id: request_id,
      method: env['REQUEST_METHOD'],
      url: env['REQUEST_URI'],
      controller: env['action_controller.instance'].class.name,
      action: env['action_controller.instance'].action_name,
      gc_stats_before: gc_stat_before,
      gc_stats_after: gc_stat_after,
      memory_before: memory_before,
      memory_after: memory_after,
      objects_before: objects_before,
      objects_after: objects_after,
      query_cache_before: query_cache_before,
      query_cache_after: query_cache_after,
      request_time: request_time,
      status: status
    }

    logger.info(log_data.to_json)
  end

  def log_memory_threshold_exceeded(request_id, memory_growth)
    log_data = {
      request_id: request_id,
      method: 'N/A',
      url: 'N/A',
      controller: 'N/A',
      action: 'N/A',
      memory_growth: memory_growth
    }

    logger.warn(log_data.to_json)
  end

  def memory_growth_exceeded?(memory_after, memory_before)
    memory_after - memory_before > @threshold
  end

  def logger
    @logger ||= Logger.new(@log_file)
  end
end
