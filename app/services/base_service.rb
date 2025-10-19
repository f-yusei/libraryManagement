# frozen_string_literal: true

class BaseService
  class << self
    def call(*args, **kwargs, &block)
      new(*args, **kwargs, &block).call
    end
  end

  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end
end
