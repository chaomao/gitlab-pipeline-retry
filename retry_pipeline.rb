require 'gitlab'
require 'logger'

# 配置 GitLab 客户端
Gitlab.configure do |config|
  config.endpoint       = 'https://jihulab.com/api/v4' # 替换为你的 GitLab 实例 URL
  config.private_token  = 'some-token'               # 替换为你的 GitLab API token
end

# 初始化日志
logger = Logger.new(STDOUT)

# 获取指定 pipeline 的失败 jobs
def get_failed_jobs(project_id, pipeline_id)
  Gitlab.pipeline_jobs(project_id, pipeline_id, scope: ['failed'])
end

# 分批重试失败的 jobs
def retry_failed_jobs_in_batches(logger, project_id, failed_jobs, batch_size = 10, wait_time = 300)
  failed_jobs.auto_paginate.each_slice(batch_size) do |batch|
    batch.each do |job|
      begin
        Gitlab.job_retry(project_id, job.id)
        logger.info("Retried job #{job.id}, #{job.name}")
      rescue => e
        logger.error("Failed to retry job #{job.id}: #{e.message}")
      end
    end
    logger.info("Waiting for #{wait_time} seconds before retrying the next batch...")
    sleep(wait_time)
  end
end

# 项目 ID 和 pipeline ID
project_id = 13953   # 替换为你的项目 ID
pipeline_id = 2912865# 替换为你的 pipeline ID

# 获取失败的 jobs 并分批重试
failed_jobs = get_failed_jobs(project_id, pipeline_id)
retry_failed_jobs_in_batches(logger, project_id, failed_jobs, 10, 600)
