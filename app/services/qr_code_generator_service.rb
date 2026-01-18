# frozen_string_literal: true

# Service to generate QR code images from data
class QrCodeGeneratorService
  # @param data [String] The data to encode in the QR code
  # @param size [Integer] QR code size (pixels). Default: 300
  # @param fill [String] Fill color (hex). Default: "#125282" (brand color)
  # @param background [String] Background color (hex). Default: "#ffffff"
  def initialize(data, size: 300, fill: "#125282", background: "#ffffff")
    @data = data.to_s
    @size = size
    @fill = fill
    @background = background
  end

  # Generate QR code as PNG binary data
  # @return [String] PNG binary data
  def generate_png
    require "rqrcode"

    qrcode = RQRCode::QRCode.new(@data)

    # Generate PNG
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 2,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: @fill,
      file: nil, # Don't write to file
      fill: @background,
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: @size
    )

    png.to_s
  end

  # Generate QR code as SVG string
  # @return [String] SVG XML string
  def generate_svg
    require "rqrcode"

    qrcode = RQRCode::QRCode.new(@data)

    qrcode.as_svg(
      offset: 0,
      color: @fill,
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true
    )
  end

  # Generate QR code and attach to ActiveStorage attachment
  # @param attachment [ActiveStorage::Attached] The attachment to assign the QR code to
  # @param format [:png, :svg] Output format (default: :png)
  # @return [Boolean] Success
  def attach_to(attachment, format: :png)
    return false if @data.blank?

    case format
    when :png
      image_data = generate_png
      filename = "qr_code_#{Time.current.to_i}.png"
      content_type = "image/png"
    when :svg
      image_data = generate_svg
      filename = "qr_code_#{Time.current.to_i}.svg"
      content_type = "image/svg+xml"
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end

    # Create a temporary file
    temp_file = Tempfile.new([ "qr_code", ".#{format}" ], encoding: "ascii-8bit")
    temp_file.write(image_data)
    temp_file.rewind

    # Attach to the record
    attachment.attach(
      io: temp_file,
      filename: filename,
      content_type: content_type
    )

    temp_file.close
    temp_file.unlink

    attachment.attached?
  rescue => e
    Rails.logger.error "QR code generation failed: #{e.message}"
    false
  end
end
