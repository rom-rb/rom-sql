# frozen_string_literal: true

module ENVHelper
  def db?(type, example)
    example.metadata[type]
  end

  def postgres?(example)
    db?(:postgres, example)
  end

  def mysql?(example)
    db?(:mysql, example)
  end

  def sqlite?(example)
    db?(:sqlite, example)
  end

  def oracle?(example)
    db?(:oracle, example)
  end

  def jruby?
    defined? JRUBY_VERSION
  end

  def pending_if_compat_mode
    pending "FIXME: not working in compat mode yet" if ENV["ROM_COMPAT"] == "true"
  end
end
