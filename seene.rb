#
# Importer plugin for Sketchup, loads scene.oemodel and texturizes it with poster.jpg (
# see https://github.com/neopaf/seene-backup to get them)
#
# Copyright 2014 Alexander Petrossian (PAF) alexander.petrossian+seene.rb@gmail.com
#
# https://github.com/neopaf/seene-backup
#

class SeeneImporter < Sketchup::Importer

       # This method is called by SketchUp to determine the description that
       # appears in the File > Import dialog's pulldown list of valid
       # importers.
       def description
         return "Seene (*.oemodel)"
       end

       # This method is called by SketchUp to determine what file extension
       # is associated with your importer.
       def file_extension
         return "oemodel"
       end

       # This method is called by SketchUp to get a unique importer id.
       def id
         return "com.sketchup.importers.seene"
       end

       # This method is called by SketchUp to determine if the "Options"
       # button inside the File > Import dialog should be enabled while your
       # importer is selected.
       def supports_options?
         return true
       end

       # This method is called by SketchUp when the user clicks on the
       # "Options" button inside the File > Import dialog. You can use it to
       # gather and store settings for your importer.
       @@skip = 2
       def do_options
         # In a real use you would probably store this information in an
         # instance variable.
         my_settings = UI.inputbox(['0=slow 2=fast'], [@@skip.to_s],
           "Seene import options")
	 if my_settings then
		@@skip = my_settings[0].to_i
	 end
       end

       # This method is called by SketchUp after the user has selected a file
       # to import. This is where you do the real work of opening and
       # processing the file.
       def load_file(file_path, status)
		model = Sketchup.active_model
		Sketchup.status_text = 'Importing Seene... (1 minute on max quality)'
			status = model.start_operation('Import Seene', true)
			begin
				result = load_file_internal(file_path, status)
			rescue Exception => e
			  UI.messagebox "Import failed: " + e.to_s # + "\n" + e.backtrace
			  raise #to display the problem in ruby console as well (should be open)
			end

			model.commit_operation
		Sketchup.status_text = ''
		return result
       end
 
       def load_file_internal(file_path, status)
folder = File.dirname(file_path)

buffer = File.binread(file_path)
version,
camera_width,
camera_height,
camera_fx,
camera_fy,
camera_k1,
camera_k2,
depthmap_width,
depthmap_height = buffer.unpack("LLLffffLL")

#@jmia claimed this did not work for her# raise "Importer works with versions 2 and 3 only, and this is version " + version.to_s unless version==3 || version==2
#3
#1936 (jpg
#1936 sizes)
#2334.201416015625 #fx?
#2334.201416015625 #fy?
#0.0
#0.0
#240
#240

header_size = 36

body = buffer[header_size, buffer.length]
depthmap = body.unpack("f*")

#puts depthmap_width

def v(x,y,depthmap,depthmap_width,depthmap_height)
	depth = depthmap[y * depthmap_width + x]
	return Geom::Point3d.new(
		x,
		-y,
		-depth * depthmap_width)
end

mesh = Geom::PolygonMesh.new

block_size = 1 + @@skip
y = 0
while y < depthmap_height-block_size
x = 0
while x < depthmap_width-block_size
	mesh.add_polygon(
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height),
		v(x+block_size, y+0, depthmap,depthmap_width,depthmap_height),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height),
	)
	mesh.add_polygon(
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height),
		v(x+0, y+block_size, depthmap,depthmap_width,depthmap_height)
	)
	x = x + block_size
end
y = y + block_size
end


model = Sketchup.active_model
group = model.entities.add_group

materials = model.materials
f_material = materials.add('Front')
f_material.texture = File.expand_path("poster.jpg",folder)
#b_material = materials.add('Back')
#b_material.texture = 'black'
b_material = f_material

#first_point = v(0, 0, depthmap,depthmap_width,depthmap_height)
last_point = v(depthmap_width-block_size, depthmap_height-block_size, depthmap,depthmap_width,depthmap_height)
#f_material.texture.size = last_point.x - first_point.x
f_material.texture.size = last_point.x
smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN
#smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN + Geom::PolygonMesh::SMOOTH_SOFT_EDGES

## Adding faces (slow)

#group.entities.add_faces_from_mesh mesh, smooth_flags, f_material, f_material
#http://www.sketchup.com/intl/en/developer/docs/ourdoc/entities#fill_from_mesh
#quote:
#It has higher performance than add_faces_from_mesh, but does less error checking as it builds the geometry.
group.entities.fill_from_mesh(mesh, false, smooth_flags, f_material, b_material)


## Setting projection properties

vector_down = Geom::Vector3d.new 0,0,1
group.entities.each { |entity|
	if entity.is_a? Sketchup::Face
		entity.set_texture_projection(vector_down,true)
		entity.set_texture_projection(vector_down,false)
		entity.casts_shadows = false
	end
}

## Moving camera

# Create a camera from scratch with an "eye" position in
# x, y, z coordinates, a "target" position that
# defines what to look at, and an "up" vector.

eye = [last_point.x/2,last_point.y/2,depthmap_width*2]
target = [last_point.x/2,last_point.y/2,0]
up = [-1,0,0]
my_camera = Sketchup::Camera.new eye, target, up, false

# Get a handle to the current view and change its camera.
view = Sketchup.active_model.active_view
view.camera = my_camera

model.shadow_info["DisplayShadows"] = true
model.shadow_info["Light"] = 100
model.shadow_info["Dark"] = 100

model.pages.add
         return 0 # 0 is the code for a successful import
       end
     end

     Sketchup.register_importer(SeeneImporter.new)

class SeeneExporter
	def self.export

		Sketchup.status_text = 'Exporting Seene...'
		begin
			export_internal
		rescue Exception => e
		  UI.messagebox "Export failed: " + e.to_s # + "\n" + e.backtrace
		  raise #to display the problem in ruby console as well (should be open)
		end

		Sketchup.status_text = ''
	end

#	def self.camera_z(fov, a)
#		Math.tan(fov/2.0 /360 * 2*Math::PI) * a/2.0
#	end

	@@skip = 2
	def self.export_internal

folder = "/tmp" # @TODO

block_size = 1 + @@skip

depthmap_width = 240 / block_size #10sec # @TODO an export option // 240
depthmap_height = depthmap_width
depthmap = Array.new(depthmap_width * depthmap_height)
model = Sketchup.active_model
view = model.active_view
#@TODO rework below code to work from existing camera point of view (and remove this block)
version =	2 # without depth_min,depth_max new fields
camera_width = 1936 # (jpg
camera_height = 1936 # sizes)
camera_fx = 2334.201416015625 #fx?
camera_fy = 2334.201416015625 #fy?
camera_k1 = 0.0
camera_k2 = 0.0
#6071mm width of picture
#fov = view.field_of_view #/ view.vpheight * view.vpwidth
#eye = [depthmap_width *block_size /2,-depthmap_height *block_size /2,depthmap_width *block_size * camera_width/camera_fx]
#eye = [depthmap_width *block_size /2,-depthmap_height *block_size /2, camera_z(fov, depthmap_width)]
#eye = [depthmap_width *block_size /2,-depthmap_height *block_size /2, depthmap_width *block_size *0.6434316354]
#eye = [depthmap_width *block_size /2,-depthmap_height *block_size /2, depthmap_width *block_size * 2]
#target = [depthmap_width *block_size /2,-depthmap_height *block_size /2,-depthmap_width]
camera_up_jpg = [0,1,0]
camera_up_human = [-1,0,0]
old_camera = view.camera
view.camera = Sketchup::Camera.new old_camera.eye, old_camera.target, camera_up_jpg, false
view.zoom_extents
view.zoom 1.05

##if false
#view.camera = Sketchup::Camera.new eye, target, camera_up_human, false; return
#camera = view.camera
#camera.eye
trace_down = Geom::Vector3d.new(0, 0, -1) #camera.direction

y = 0
while y < depthmap_height
x = 0
while x < depthmap_width
=begin
	return Geom::Point3d.new(
		x,
		-y,
		-depth * depthmap_width)
=end
	ray = [Geom::Point3d.new(x * block_size, -y * block_size, 0), trace_down]
	hit = model.raytest(ray, true) # Ignore hidden geometry when computing intersections.
	if hit == nil
		depth = 10 # "far away"
	else
		depth = -hit[0].z / block_size / depthmap_width
	end
	depthmap[y * depthmap_width + x] = depth

	x = x + 1
end
y = y + 1
end

File.binwrite(File.expand_path("scene.oemodel",folder),
[version,
camera_width,
camera_height,
camera_fx,
camera_fy,
camera_k1,
camera_k2,
depthmap_width,
depthmap_height]
.concat(depthmap)
.pack("LLLffffLLf*"))
##end

  keys = {
    :filename => File.expand_path("poster.jpg",folder),
    :width => camera_width,
    :height => camera_height,
    :antialias => true,
    :transparent => false
  }
  view.write_image keys

view.camera = Sketchup::Camera.new old_camera.eye, old_camera.target, camera_up_human, false
view.zoom_extents
view.zoom 1.05
UI.messagebox "Exported to " + folder
	end
end

unless file_loaded?(__FILE__)
	UI.menu("Plugins").add_item("Export Seene...") { SeeneExporter.export }
end
 
file_loaded(__FILE__)

#UI.messagebox("hi")
