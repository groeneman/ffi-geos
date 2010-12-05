
$: << File.dirname(__FILE__)
require 'test_helper'

class UtilsTests < Test::Unit::TestCase
  include TestHelper

  if defined?(Geos::Utils)
    def test_orientation_index
      assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 5, 0))
      assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 10, 0))
      assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 0, 0))
      assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, -5, 0))
      assert_equal(0,  Geos::Utils.orientation_index(0, 0, 10, 0, 20, 0))
      assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 6))
      assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 20))
      assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, 3))
      assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 5, -2))
      assert_equal(1,  Geos::Utils.orientation_index(0, 0, 10, 10, 1000000, 1000001))
      assert_equal(-1,  Geos::Utils.orientation_index(0, 0, 10, 10, 1000000,  999999))
    end
  end

  def create_method_tester(expected, method, cs, type_id, klass)
    geom = Geos.send(method, cs)
    expected_geom = read(expected)

    assert(expected_geom.eql_exact?(geom, TOLERANCE))
    assert(geom.valid?)
    assert_instance_of(klass, geom)
    assert_equal(type_id, geom.type_id)

    yield geom if block_given?
  end

  def test_create_point
    cs = Geos::CoordinateSequence.new(1, 2)
    cs.set_x(0, 10)
    cs.set_y(0, 20)

    create_method_tester('POINT(10 20)', :create_point, cs, Geos::GEOS_POINT, Geos::Point)
  end

  def test_bad_create_point
    cs = Geos::CoordinateSequence.new(0, 0)
    assert_raise(RuntimeError) do
      geom = Geos.create_point(cs)
    end
  end

  def test_create_line_string
    cs = Geos::CoordinateSequence.new(2, 3)
    cs.set_x(0, 10)
    cs.set_y(0, 20)
    cs.set_z(0, 30)
    cs.set_x(1, 30)
    cs.set_y(1, 20)
    cs.set_z(1, 10)

    create_method_tester(
      'LINESTRING (10 20 30, 30 20 10)',
      :create_line_string,
      cs,
      Geos::GEOS_LINESTRING,
      Geos::LineString
    ) do |geom|
      assert(!geom.empty?)
      assert(geom.valid?)
      assert(geom.simple?)
      assert(!geom.ring?)
      assert(geom.has_z?)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_create_bad_line_string
    cs = Geos::CoordinateSequence.new(1, 0)
    assert_raise(RuntimeError) do
      geom = Geos::create_line_string(cs)
    end
  end

  def test_create_linear_ring
    cs = Geos::CoordinateSequence.new(4,3)
    cs.set_x(0, 7)
    cs.set_y(0, 8)
    cs.set_z(0, 9)
    cs.set_x(1, 3)
    cs.set_y(1, 3)
    cs.set_z(1, 3)
    cs.set_x(2, 11)
    cs.set_y(2, 15.2)
    cs.set_z(2, 2)
    cs.set_x(3, 7)
    cs.set_y(3, 8)
    cs.set_z(3, 9)

    create_method_tester(
      'LINEARRING (7 8 9, 3 3 3, 11 15.2 2, 7 8 9)',
      :create_linear_ring,
      cs,
      Geos::GEOS_LINEARRING,
      Geos::LinearRing
    ) do |geom|
      assert(!geom.empty?)
      assert(geom.valid?)
      assert(geom.simple?)
      assert(geom.ring?)
      assert(geom.has_z?)
      assert_equal(1, geom.num_geometries)
    end
  end

  def test_bad_create_linear_ring
    cs = Geos::CoordinateSequence.new(1, 0)

    assert_raise(RuntimeError) do
      geom = Geos::create_linear_ring(cs)
    end
  end

  def test_create_polygon
    cs = Geos::CoordinateSequence.new(5, 2)
    cs.set_x(0, 0)
    cs.set_y(0, 0)

    cs.set_x(1, 0)
    cs.set_y(1, 10)

    cs.set_x(2, 10)
    cs.set_y(2, 10)

    cs.set_x(3, 10)
    cs.set_y(3, 0)

    cs.set_x(4, 0)
    cs.set_y(4, 0)

    exterior_ring = Geos::create_linear_ring(cs)

    geom = Geos::create_polygon(exterior_ring)
    assert_instance_of(Geos::Polygon, geom)
    assert_equal('Polygon', geom.geom_type)
    assert_equal(Geos::GEOS_POLYGON, geom.type_id)
    assert(read('POLYGON ((0 0, 0 10, 10 10, 10 0, 0 0))').eql_exact?(geom, TOLERANCE))
  end

  def test_create_polygon_with_holes
    create_ring = lambda { |*points|
      Geos.create_linear_ring(
        Geos::CoordinateSequence.new(points.length, 2).tap { |cs|
          points.each_with_index do |(x, y), i|
            cs.set_x(i, x)
            cs.set_y(i, y)
          end
        }
      )
    }

    exterior_ring = create_ring[
      [ 0, 0 ],
      [ 0, 10 ],
      [ 10, 10 ],
      [ 10, 0 ],
      [ 0, 0 ]
    ]

    hole_1 = create_ring[
      [ 2, 2 ],
      [ 2, 4 ],
      [ 4, 4 ],
      [ 4, 2 ],
      [ 2, 2 ]
    ]

    hole_2 = create_ring[
      [ 6, 6 ],
      [ 6, 8 ],
      [ 8, 8 ],
      [ 8, 6 ],
      [ 6, 6 ]
    ]

    geom = Geos::create_polygon(exterior_ring, [ hole_1, hole_2 ])
    assert_instance_of(Geos::Polygon, geom)
    assert_equal('Polygon', geom.geom_type)
    assert_equal(Geos::GEOS_POLYGON, geom.type_id)

    assert(!geom.empty?)
    assert(geom.valid?)
    assert(geom.simple?)
    assert(!geom.ring?)
    assert(!geom.has_z?)

    assert_equal(1, geom.num_geometries)
  end
end
