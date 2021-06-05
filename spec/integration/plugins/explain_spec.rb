require "yaml"

RSpec.describe "Plugins / :explain", :postgres do
  include_context "users and tasks"

  before do
    conf.plugin(:sql, relations: :pg_explain)
  end

  it "returns the execution plan of a request" do
    expect(users.explain).to match(/(Index|Seq Scan)|Sort/)
  end

  it "supports JSON format" do
    plan = users.explain(format: :json)

    expect(plan).to be_a(Hash)
    expect(plan["Node Type"]).to match(/(Index|Seq Scan)|Sort/)
  end

  it "supports YAML format" do
    yaml = YAML.load(users.explain(format: :yaml))[0]
    expect(yaml["Plan"]["Node Type"]).to match(/(Index|Seq Scan)|Sort/)
  end

  it "supports the ANALYZE option" do
    expect(users.explain(analyze: true)).to match(/Execution time/i)
  end

  it "supports the VERBOSE option" do
    expect(users.explain(verbose: true)).to match(/Output: id, name/)
  end

  it "supports the COSTS option" do
    expect(users.explain(costs: false)).not_to match(/cost/)
  end

  it "supports the BUFFERS option" do
    expect(users.explain(analyze: true, buffers: true)).to match(/Buffers:/)
  end

  it "supports the TIMING option" do
    expect(users.explain(analyze: true, timing: false)).not_to match(/actual time/)
  end
end
