RSpec.describe ROM::Relation, '#unfiltered' do
  subject(:relation) { relations[:tasks].select(:id, :title) }

  include_context 'users and tasks'

  with_adapters do
    it 'nullifies a relation which has records' do
      pending 'not working on JRuby' if defined?(JRUBY_VERSION)
      expect(relation.to_a).not_to be_empty
      expect(relation.nullify.to_a).to be_empty
    end
  end
end
