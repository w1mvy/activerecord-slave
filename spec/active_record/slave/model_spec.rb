describe ActiveRecord::Slave::Model do
  it "connect to master" do
    expect(User.connection.pool.spec.config[:port]).to eq 21891
  end

  it "connect to slaves" do
    User.on_slave do
      slave_ports = 10.times.map { User.connection.pool.spec.config[:port] }.uniq
      expect(slave_ports.count).to eq 2
      expect(slave_ports).to include 21892
      expect(slave_ports).to include 21893
    end
  end

  it "connect to default" do
    expect(Item.connection.pool.spec.config[:port]).to eq 3306
  end

  describe "Write to master, Read from slave" do
    it "returns user object from slave database" do
      user_from_master = User.create name: "alice"

      user_from_slave  = User.on_slave do
                           User.find user_from_master.id
                         end

      expect(user_from_master).to eq user_from_slave
    end
  end

  describe "Assosiations" do
    let(:user) { User.create name: "alice" }
    let(:item) { Item.create name: "foo", count: 1, user: user }

    it "returns user object, belongs_to" do
      expect(item.user).to be_a User
      expect(item.user.id).to eq user.id
    end

    it "Add has_many object" do
      expect { item }.to change { user.items.count }.from(0).to(1)
      expect { Item.create name: "var", count: 1, user: user }.to change { user.items.count }.from(1).to(2)
    end

    context "Enable DatabaseRewinder, delete records at each after specs" do
      it "No records in DataBases" do
        expect(User.all.count).to eq 0
        expect(Item.all.count).to eq 0
      end
    end
  end
end