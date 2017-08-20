require "mini_magick"
require "yaml"

MAX_DIMENSION = 750
search_directory = "./pictures"
galleries_config = "./_data/galleries.yml"

search_directory = File.expand_path(search_directory)

galleries =
  if File.exist? galleries_config
    YAML.load_file(galleries_config)
  else
    {}
  end

# puts galleries

def titleize(s)
  s.downcase.gsub(/\b('?[a-z])/) { $1.capitalize }
end

# - name: 20170818_0255.jpg
  # thumb: thumb-1.jpg
  # text: The first image

def process_image(path)
  picture_name = File.basename(path)
  thumbnail_dir = File.join(File.dirname(path), "thumbnails")
  thumbnail_path = File.join(thumbnail_dir, picture_name)
  Dir.mkdir(thumbnail_dir) unless File.exist?(thumbnail_dir)

  image = MiniMagick::Image.open(path)

  image_prop = {
    "name" => picture_name,
    "thumb" => "thumbnails/#{picture_name}",
    "height" => image.height,
    "width" => image.width
  }

  return image_prop if File.exist?(thumbnail_path)

  image.resize "#{MAX_DIMENSION}>"
  image.write thumbnail_path
  image_prop
end

Dir["#{search_directory}/*/"].each do |dir|
  imagefolder = File.basename(dir)
  # puts imagefolder
  gallery_index = galleries.index{ |g| g["imagefolder"] == imagefolder }

  gallery = if gallery_index
      galleries[gallery_index]
    else
      {}
    end

  gallery["name"] ||= titleize(imagefolder)
  gallery["imagefolder"] ||= imagefolder
  gallery["description"] ||= ""
  pictures = gallery["pictures"] || []
  new_pictures = []
  gallery["pictures"] = []

  Dir["#{dir}*"].each do |pic|
    next if File.directory? pic
    begin
      image = process_image(pic)
    rescue => e
      puts "An error occured while process #{pic}: #{e}"
    end

    picture_index = pictures.index{ |pic| pic["name"] == image["name"]}
    puts picture_index

    if picture_index
      gallery["pictures"][picture_index] = pictures[picture_index].merge(image)
    else
      new_pictures.push(image)
    end
  end
  gallery["pictures"].concat(new_pictures)
  # remove nils
  gallery["pictures"].compact!

  if gallery_index
    galleries[gallery_index] = gallery
  else
    galleries.push(gallery)
  end
end

File.write(galleries_config, galleries.to_yaml)

# image = MiniMagick::Image.open("pictures/dogs/1.jpg")
# puts image.dimensions
# image.resize "#{max_dimension}>"
# image.format "jpg"
# image.write "output.png"
