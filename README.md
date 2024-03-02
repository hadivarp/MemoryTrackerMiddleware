# Memory Tracker Middleware for Rails

In my recent Rails project, I discovered memory leaks causing my app to restart in some cases. To address this issue, I delved into understanding memory leaks and developed a middleware to trace logs, providing insights into memory fluctuations during requests.

## Installation

1. Add the `memory_tracker` folder inside the `lib` directory.
2. Include the following line in your `application.rb` file:

    ```ruby
    config.middleware.use MemoryTrackerMiddleware, threshold: 20, log_file: Rails.root.join('log', 'memory_tracker.log')
    ```

   This sets the memory growth threshold to 20 MB. If the memory growth between two requests exceeds this threshold, the middleware will log a warning about potential memory issues.

3. Install the required gems:

   ```ruby
   gem 'memory_profiler'
   gem 'sys-proctable'
   ```
   
## Usage

The middleware uses the memory_profiler and sys-proctable gems to provide detailed information about memory usage and garbage collection.

## Log Output

The logs will contain information about each request's memory statistics. For example:

```
I, [2024-03-02T15:00:44.012919 #26872]  INFO -- : {"request_id":"670086b2-cde1-432a-9ffe-84efa847f295", ...}
W, [2024-03-02T15:00:44.013239 #26872]  WARN -- : {"request_id":"670086b2-cde1-432a-9ffe-84efa847f295", "memory_growth":25111298048}
```

## Log Details

* **request_id:** Unique identifier for each request.
* **method, url, controller, action:** Request details.
* **gc_stats_before, gc_stats_after:** GC stats before and after the request.
* **memory_before, memory_after:** Memory usage before and after the request (in MB).
* **objects_before, objects_after:** Object counts before and after the request.
* **query_cache_before, query_cache_after:** Query cache size before and after the request.
* **request_time:** Time taken for the request.

## Performance Considerations

* The impact of the MemoryTrackerMiddleware on the performance of your Rails application depends on various factors, including the frequency and intensity of memory tracking, the overall load on your application, and the available system resources.

Here are some considerations:

## Overhead of Memory Tracking:

The memory tracking itself involves capturing the state of garbage collection, memory usage, and other metrics. This process adds some computational overhead.
If the middleware is configured to log extensively or if memory tracking is performed too frequently, it can contribute to increased processing time for each request.

## Frequency of Logging:

Logging detailed memory information for every request can impact performance. Consider adjusting the frequency of logging or providing an option to enable/disable the middleware based on your application's needs

## Resource Utilization:

The middleware uses external gems (memory_profiler and sys-proctable) to gather memory-related information. These gems may have their own resource requirements.
Frequent memory profiling can lead to increased CPU and memory usage.

## File I/O for Logging:

Writing logs to a file (memory_tracker.log) involves file I/O operations, which can introduce latency. If your application experiences high traffic, consider using asynchronous logging or other techniques to mitigate this impact.

## Impact on Development vs. Production:

While tracking memory in development can be useful for debugging, it might be advisable to disable or reduce the intensity of memory tracking in production to minimize performance impact.

## Assessing Performance Impact:

To assess the specific impact on your Rails application's performance, you can:

Profile your application using tools like Ruby's built-in Benchmark module or more advanced profilers.
Monitor system resources using tools like New Relic, Scout, or other performance monitoring solutions.

It's recommended to use the MemoryTrackerMiddleware judiciously, considering the trade-off between the benefits of memory tracking and the potential impact on performance. Always test in a staging environment to evaluate the impact before deploying such middleware to production.



## Visualizing Results

To make memory tracking results more visual, consider using tools like Grafana. You may need to parse and import log data into a time-series database for better visualization.

## Notes

Ensure that the log file (memory_tracker.log) is configured for structured JSON logs for better visualization.

Happy tracking!

Feel free to adjust the content as per your specific requirements or add any additional details you find relevant.

