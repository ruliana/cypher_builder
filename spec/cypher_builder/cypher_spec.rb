require 'spec_helper'

describe Cypher do
  let(:adapter) { instance_spy(Adapter::Neography) }
  describe '.exec' do
    it 'executes with default adapter' do
      c = Node('c')
      cypher_class = Cypher(Match(c),
                            Return(c.name))
      cypher_class.exec(adapter)
      expect(adapter).to have_received(:execute).with('MATCH (c) RETURN c.name AS name', {})
    end
  end
  describe '#execute' do
    it 'executes an empty query' do
      cypher_class = Cypher()
      cypher_class.new(adapter).execute
      expect(adapter).to have_received(:execute).with('', {})
    end
    it 'executes a simple query' do
      c = Node('c')
      cypher_class = Cypher(Match(c),
                            Return(c.name))
      cypher_class.new(adapter).execute
      expect(adapter).to have_received(:execute).with('MATCH (c) RETURN c.name AS name', {})
    end
    it 'executes a query with relationships' do
      c = Node('c')
      n = Node('n')
      r = Rel('r', labels: 'TEST')
      cypher_class = Cypher(Match(r.from(c).to(n)),
                            Return(c.name))
      cypher_class.new(adapter).execute
      expect(adapter).to have_received(:execute).with('MATCH (c)-[r:TEST]->(n) RETURN c.name AS name', {})
    end
    it 'executes the most complex query possible (exercises everything currently implemented)' do
      c = Node('c', labels: 'what')
      v = Node('v', labels: 'other')
      n = Node('n')
      r = Rel('r')
      cypher_class = Cypher(Match(r.from(c).to(n), v),
                            Where(And(Eql(c.stuff, Param('thing')),
                                      Like(c.staff, 'test%'))),
                            Return(c.name, Alias(c.stuff, 'something')),
                            OrderBy(c.name, :desc, c.stuff),
                            Limit(10))
      cypher_class.new(adapter).execute(thing: 'of course')
      expect(adapter).to have_received(:execute).with('MATCH (c:what)-[r]->(n), (v:other) WHERE c.stuff = {thing} AND c.staff LIKE "test%" RETURN c.name AS name, c.stuff AS something ORDER BY c.name desc, c.stuff LIMIT 10', {thing: 'of course'})
    end
    context 'with Opt' do
      before do
        c = Node('c')
        @cypher_class = Cypher(Match(c),
                               Opt(name: Return(c.name),
                                   thing: Return(c.thing)))

        @cypher_class2 = Cypher(Match(c),
                                Where(Opt(name: Eql(c.name, Param('name')),
                                          thing: Eql(c.thing, Param('thing')))),
                                Return(Opt(name: c.name, thing: c.thing)))
      end
      it 'generates first option' do
        @cypher_class.new(adapter).execute(name: true)
        expect(adapter).to have_received(:execute).with('MATCH (c) RETURN c.name AS name', {})
      end
      it 'generates first option with multiple uses' do
        @cypher_class2.new(adapter).execute(name: 'Testing Test')
        expect(adapter).to have_received(:execute).with('MATCH (c) WHERE c.name = {name} RETURN c.name AS name', {name: 'Testing Test'})
      end
      it 'generates second option' do
        @cypher_class.new(adapter).execute(thing: true)
        expect(adapter).to have_received(:execute).with('MATCH (c) RETURN c.thing AS thing', {})
      end
      it 'generates second option with multiple uses' do
        @cypher_class2.new(adapter).execute(thing: 123)
        expect(adapter).to have_received(:execute).with('MATCH (c) WHERE c.thing = {thing} RETURN c.thing AS thing', {thing: 123})
      end
      it 'defaults to firts option' do
        @cypher_class.new(adapter).execute
        expect(adapter).to have_received(:execute).with('MATCH (c) RETURN c.name AS name', {})
      end
    end
  end
end