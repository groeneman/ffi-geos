# encoding: UTF-8
# frozen_string_literal: true

module Geos
  class WkbWriter
    include Geos::Tools

    attr_reader :ptr

    def initialize(options = {})
      options = {
        :include_srid => false
      }.merge(options)

      ptr = FFIGeos.GEOSWKBWriter_create_r(Geos.current_handle_pointer)
      @ptr = FFI::AutoPointer.new(
        ptr,
        self.class.method(:release)
      )

      set_options(options)
    end

    def self.release(ptr) #:nodoc:
      FFIGeos.GEOSWKBWriter_destroy_r(Geos.current_handle_pointer, ptr)
    end

    # Options can be set temporarily for individual writes using an options
    # Hash. The only option currently available is :include_srid.
    def write(geom, options = nil)
      unless options.nil?
        old_options = {
          :include_srid => self.include_srid
        }

        set_options(options)
      end

      size_t = FFI::MemoryPointer.new(:size_t)
      FFIGeos.GEOSWKBWriter_write_r(Geos.current_handle_pointer, self.ptr, geom.ptr, size_t).get_bytes(0, size_t.read_int)
    ensure
      set_options(old_options) unless old_options.nil?
    end

    def write_hex(geom, options = nil)
      unless options.nil?
        old_options = {
          :include_srid => self.include_srid
        }

        set_options(options)
      end

      size_t = FFI::MemoryPointer.new(:size_t)
      FFIGeos.GEOSWKBWriter_writeHEX_r(Geos.current_handle_pointer, self.ptr, geom.ptr, size_t).get_string(0, size_t.read_int)
    ensure
      set_options(old_options) unless old_options.nil?
    end

    def output_dimensions=(dim)
      if dim < 2 || dim > 3
        raise ArgumentError.new("Output dimensions must be either 2 or 3")
      end
      FFIGeos.GEOSWKBWriter_setOutputDimension_r(Geos.current_handle_pointer, self.ptr, dim)
    end

    def output_dimensions
      FFIGeos.GEOSWKBWriter_getOutputDimension_r(Geos.current_handle_pointer, self.ptr)
    end

    def include_srid
      bool_result(FFIGeos.GEOSWKBWriter_getIncludeSRID_r(Geos.current_handle_pointer, self.ptr))
    end

    def include_srid=(val)
      FFIGeos.GEOSWKBWriter_setIncludeSRID_r(Geos.current_handle_pointer, self.ptr,
        Geos::Tools.bool_to_int(val)
      )
    end

    def byte_order
      FFIGeos.GEOSWKBWriter_getByteOrder_r(Geos.current_handle_pointer, self.ptr)
    end

    def byte_order=(val)
      check_enum_value(Geos::ByteOrders, val)
      FFIGeos.GEOSWKBWriter_setByteOrder_r(Geos.current_handle_pointer, self.ptr, val)
    end

    private
      def set_options(options) #:nodoc:
        [ :include_srid ].each do |k|
          self.send("#{k}=", options[k]) if options.has_key?(k)
        end
      end
  end
end
