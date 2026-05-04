# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Plugins / :pg_full_text_search', :postgres do
  include_context 'users and tasks'

  setup_tables do
    conf.plugin(:sql, relations: :pg_full_text_search)
  end

  it 'searches against the provided columns' do
    task = conn[:tasks].insert id: 3, user_id: 1, title: 'Apples'
    result = tasks.full_text_search([:title], 'apple', language: 'english').pluck(:id)

    expect(result).to contain_exactly(task)
  end

  it 'handles ROM::SQL::Attribute types' do
    task = conn[:tasks].insert id: 3, user_id: 1, title: 'Apples'
    result = tasks.full_text_search([tasks[:title]], 'apple', language: 'english').pluck(:id)

    expect(result).to contain_exactly(task)
  end

  context 'when handling complex queries' do
    specify do
      searched_users = users.full_text_search([:name], 'Joe', language: 'simple')
      result = tasks.exists(searched_users).pluck(:id)

      expect(result).to contain_exactly(1)
    end
  end
end
