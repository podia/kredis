require "test_helper"
require "active_support/core_ext/object/inclusion"

class SetTest < ActiveSupport::TestCase
  setup { @set = Kredis.set "myset" }

  test "add" do
    @set.add(%w[ 1 2 3 ])
    @set << 4
    @set << 4
    assert_equal %w[ 1 2 3 4 ], @set.members
  end

  test "add nothing" do
    @set.add(%w[ 1 2 3 ])
    @set.add([])
    assert_equal %w[ 1 2 3 ], @set.to_a
  end

  test "remove" do
    @set.add(%w[ 1 2 3 4 ])
    @set.remove(%w[ 2 3 ])
    @set.remove("1")
    assert_equal %w[ 4 ], @set.members
  end

  test "remove nothing" do
    @set.add(%w[ 1 2 3 4 ])
    @set.remove([])
    assert_equal %w[ 1 2 3 4 ], @set.members
  end

  test "replace" do
    @set.add(%w[ 1 2 3 4 ])
    @set.replace(%w[ 5 6 ])
    assert_equal %w[ 5 6 ], @set.members
  end

  test "include" do
    @set.add("1", "2", "3", "4")
    assert @set.include?("1")
    assert_not @set.include?("5")

    assert "1".in?(@set)
  end

  test "size" do
    @set.add(%w[ 1 2 3 4 ])
    assert_equal 4, @set.size
  end

  test "take" do
    @set.add("1")
    assert_equal "1", @set.take

    @set.add(%w[ 1 2 3 4 ])
    assert @set.take.in? %w[ 1 2 3 4 ]
  end

  test "clear" do
    @set.add("1")
    @set.clear
    assert_equal [], @set.members
  end

  test "-" do
    @set.add %w[1 2 3 4 5]
    subset = Kredis.set "otherset"
    subset.add %w[2 3 4]
    assert_equal (@set - subset), %w[1 5]
  end

  test "diff" do
    @set.add %w[1 2 3 4 5]
    subset = Kredis.set "otherset"
    subset.add %w[2 3 4]
    assert_equal (@set.diff(subset)), %w[1 5]

    result = Kredis.set "resultset"
    @set.diff(subset, store: result)
    assert_equal result.members, %w[1 5]
  end

  test "+" do
    @set.add %w[1 2 3 4 5]
    otherset = Kredis.set "otherset"
    otherset.add %w[5 6 7 8 9]
    assert_equal (@set + otherset), %w[1 2 3 4 5 6 7 8 9]
  end

  test "union" do
    @set.add %w[1 2 3 4 5]
    otherset = Kredis.set "otherset"
    otherset.add %w[5 6 7 8 9]
    assert_equal (@set.union(otherset)), %w[1 2 3 4 5 6 7 8 9]

    result = Kredis.set "resultset"
    @set.union(otherset, store: result)
    assert_equal result.members, %w[1 2 3 4 5 6 7 8 9]
  end

  test "&" do
    @set.add %w[1 2 3 4 5]
    otherset = Kredis.set "otherset"
    otherset.add %w[4 5 6 7]
    assert_equal (@set & otherset), %w[4 5]
  end

  test "intersection" do
    @set.add %w[1 2 3 4 5]
    otherset = Kredis.set "otherset"
    otherset.add %w[4 5 6 7]
    assert_equal (@set.intersection(otherset)), %w[4 5]

    result = Kredis.set "resultset"
    @set.intersection(otherset, store: result)
    assert_equal result.members, %w[4 5]
  end

  test "typed as floats" do
    @set = Kredis.set "mylist", typed: :float

    @set.add 1.5, 2.7
    @set << 2.7
    assert_equal [ 1.5, 2.7 ], @set.members

    @set.remove(2.7)
    assert_equal [ 1.5 ], @set.members
  end

  test "failing open" do
    stub_redis_down(@set) do
      @set.add "1"
      assert_equal [], @set.members
      assert_equal 0, @set.size
    end
  end
end
