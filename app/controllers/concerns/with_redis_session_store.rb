module WithRedisSessionStore
  private

  def redis_session_store(suffix)
    raise 'session_id is not found' unless current_session_id

    redis = Redis::Namespace.new(['redis_session_store', current_session_id, suffix].join(':'))
    yield(redis) if block_given?
    redis
  end

  def current_session_id
    session.send(:load_for_write!) unless session.id
    session.id
  end
end
