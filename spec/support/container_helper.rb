# frozen_string_literal: true

module ContainerHelper
  Entry = ::Struct.new(:block, :provides, :depends_on)

  def self.install(config)
    config.extend(DSL)
    config.include(InstanceMethods)
  end

  def self.parse_dependency(arg)
    case arg
    when nil
      [nil, []]
    when ::Symbol
      [arg, []]
    when ::Hash
      raise ::ArgumentError, "expected a single-key hash, got #{arg.inspect}" if arg.size != 1

      key, value = arg.first
      [key, Array(value)]
    else
      raise ::ArgumentError, "expected a Symbol or a single-key Hash, got #{arg.inspect}"
    end
  end

  def self.sort_entries(entries)
    sorted, unsorted = entries.partition(&:provides)
    by_name = sorted.to_h { |entry| [entry.provides, entry] }
    state = {}
    result = []

    visit = lambda do |entry|
      case state[entry]
      when :done then return
      when :visiting then raise "circular dependency detected at #{entry.provides.inspect}"
      end

      state[entry] = :visiting
      entry.depends_on.each do |dep_name|
        dep_entry = by_name[dep_name]
        visit.call(dep_entry) if dep_entry
      end
      state[entry] = :done
      result << entry
    end

    sorted.each(&visit)
    result.concat(unsorted)
  end

  module DSL
    def container_blocks
      @container_blocks ||= ::Hash.new do |hash, key|
        hash[key] = []
      end
    end

    def all_blocks(group)
      entries = ancestors.select { |ancestor|
        ancestor.is_a?(::Class) && ancestor.respond_to?(:container_blocks)
      }.reverse.flat_map { |klass| klass.container_blocks[group] }

      ContainerHelper.sort_entries(entries).map(&:block)
    end

    def setup_relations(dependency = nil, &block)
      provides, depends_on = ContainerHelper.parse_dependency(dependency)
      container_blocks[:relations] << Entry.new(block, provides, depends_on)
    end

    def seed(dependency = nil, &block)
      provides, depends_on = ContainerHelper.parse_dependency(dependency)
      container_blocks[:seeds] << Entry.new(block, provides, depends_on)
    end

    def setup_tables(dependency = nil, &block)
      provides, depends_on = ContainerHelper.parse_dependency(dependency)
      container_blocks[:tables] << Entry.new(block, provides, depends_on)
    end
  end

  module InstanceMethods
    def self.included(base)
      base.let(:container) do |example|
        self.class.all_blocks(:tables).each do |block|
          instance_exec(example, &block)
        end

        self.class.all_blocks(:relations).each do |block|
          instance_exec(example, &block)
        end

        ::ROM.container(conf)
      end

      base.before do |example|
        seeds = self.class.all_blocks(:seeds)

        if seeds.any?
          container

          seeds.each do |block|
            instance_exec(example, &block)
          end
        end
      end
    end
  end
end
