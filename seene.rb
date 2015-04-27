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
		Sketchup.status_text = 'Importing Seene... (about 1 minute on max quality)'
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
if version!=2
	header_size=44
end
#puts "version[#{version}]"

body = buffer[header_size, buffer.length]
depthmap = body.unpack("f*")

#puts depthmap_width

def v(x,y,depthmap,depthmap_width,depthmap_height,xk,yk)
	depth = depthmap[y * depthmap_width + x]
#	return Geom::Point3d.new(
#               x,
#               -y,
#		-depth * depthmap_height)
	return Geom::Point3d.new(
		depth * ((x + 0.5) / depthmap_width - 0.5) / xk * 1000,
		-depth * ((y + 0.5) / depthmap_height - 0.5) / yk * 1000,
		-(depth - 1) * 1000)
end

mesh = Geom::PolygonMesh.new

xk = camera_fx / camera_width
yk = camera_fy / camera_height

vertex2point = Hash.new

block_size = 1 + @@skip
y = 0
while y < depthmap_height-block_size
x = 0
while x < depthmap_width-block_size
	mesh.add_polygon(
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		v(x+block_size, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk),
	)
	mesh.add_polygon(
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk),
		v(x+0, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk)
	)
	x = x + block_size
end
y = y + block_size
end


model = Sketchup.active_model
group = model.entities.add_group

materials = model.materials
material = materials.add
material.texture = File.expand_path("poster.jpg",folder)

#first_point = v(0, 0, depthmap,depthmap_width,depthmap_height)
##last_point = v(depthmap_width-1, depthmap_height-1, depthmap,depthmap_width,depthmap_height,xk,yk)
#puts "last_point[#{last_point}]"
#f_material.texture.size = last_point.x - first_point.x
##f_material.texture.size = last_point.x * 2
smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN
#smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN + Geom::PolygonMesh::SMOOTH_SOFT_EDGES

## Adding faces (slow)

#group.entities.add_faces_from_mesh mesh, smooth_flags, material, material
#http://www.sketchup.com/intl/en/developer/docs/ourdoc/entities#fill_from_mesh
#quote:
#It has higher performance than add_faces_from_mesh, but does less error checking as it builds the geometry.
group.entities.fill_from_mesh(mesh, false, smooth_flags) #, material, material


## Setting projection properties

vector_down = Geom::Vector3d.new 0,0,1

faces = []
group.entities.each { |entity|
	if entity.is_a? Sketchup::Face
		faces << entity
		entity.set_texture_projection(vector_down,true)
		entity.set_texture_projection(vector_down,false)
		entity.casts_shadows = false
	end
}

def p(x,y,depthmap_width,depthmap_height)
	return Geom::Point3d.new(
		(x + 0.5) / depthmap_width,
		1 - (y + 0.5) / depthmap_height,
		0)
end

i = 0
y = 0
while y < depthmap_height-block_size
x = 0
while x < depthmap_width-block_size
	face = faces[i];	i = i + 1
	if face == nil
		UI.messagebox("Less faces were generated then expected, texture is probably misaligned a bit (1)")
		break
	end
	pt_array = [
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+0, y+0,          depthmap_width,depthmap_height),
		v(x+block_size, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+block_size, y+0,          depthmap_width,depthmap_height),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+block_size, y+block_size,          depthmap_width,depthmap_height)
	]
	face.position_material(material, pt_array, false)
	face.position_material(material, pt_array, true)

	face = faces[i];	i = i + 1
	if face == nil
		UI.messagebox("Less faces were generated then expected, texture is probably misaligned a bit (1)")
		break
	end
	pt_array = [
		v(x+0, y+0, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+0, y+0,          depthmap_width,depthmap_height),
		v(x+block_size, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+block_size, y+block_size,          depthmap_width,depthmap_height),
		v(x+0, y+block_size, depthmap,depthmap_width,depthmap_height,xk,yk),
		p(x+0, y+block_size,          depthmap_width,depthmap_height)
	]
	face.position_material(material, pt_array, false)
	face.position_material(material, pt_array, true)

	x = x + block_size
end
y = y + block_size
end


## Moving camera

# Create a camera from scratch with an "eye" position in
# x, y, z coordinates, a "target" position that
# defines what to look at, and an "up" vector.

eye = [0,0,1 * 1000]
target = [0,0,0]
up = [-1,0,0]
my_camera = Sketchup::Camera.new eye, target, up, true

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
	@@debug = false
	def self.export

		Sketchup.status_text = 'Exporting Seene... (about 2 minutes on max quality)'
		begin
			model = Sketchup.active_model
			if @@debug
				status = model.start_operation('Export Seene Debug', true)
			end
			export_internal
			if @@debug
				model.commit_operation
			end
		rescue Exception => e
		  UI.messagebox "Export failed: " + e.to_s # + "\n" + e.backtrace
		  raise #to display the problem in ruby console as well (should be open)
		end

		Sketchup.status_text = ''
	end

#	def self.camera_z(fov, a)
#		Math.tan(fov/2.0 /360 * 2*Math::PI) * a/2.0
#	end

	@@skip = 0
	@@distance_k = 1
	def self.export_internal

folder = "/tmp" # @TODO

block_size = 1 + @@skip

depthmap_width = 240 / block_size #10sec # @TODO an export option // 240
depthmap_height = depthmap_width
distancemap = Array.new(depthmap_width * depthmap_height)
depthmap = Array.new(depthmap_width * depthmap_height)
model = Sketchup.active_model
view = model.active_view
camera = view.camera

#old_camera = camera
#view.camera = Sketchup::Camera.new old_camera.eye, old_camera.target, old_camera.xaxis.reverse, false; return

version =	2 # without depth_min,depth_max new fields
camera_height = view.vpheight*2 # sizes)
camera_width = camera_height # (jpg
camera_fx = 2334.201416015625 #fx?
camera_fy = 2334.201416015625 #fy?
camera_k1 = 0.0
camera_k2 = 0.0

mesh = Geom::PolygonMesh.new

distance_min = 1e20
distance_max = 0
distance_total = 0
distance_n = 0

eye = camera.eye

if view.vpwidth < view.vpheight
	UI.messagebox "Please resize your window show it will be square or wider than taller"
	return
end
vp_x_base = (view.vpwidth - view.vpheight) / 2

y = 0.0
while y < depthmap_height
x = 0.0
while x < depthmap_width
=begin
	return Geom::Point3d.new(
		x,
		-y,
		-depth * depthmap_width)
=end
	ray = view.pickray(
		(1-y/depthmap_height) * view.vpheight + vp_x_base,
		x/depthmap_width * view.vpheight)
	hit = model.raytest(ray, true) # Ignore hidden geometry when computing intersections.
	if hit == nil
		distance = -1 # "far away"
		if @@debug
			mesh.add_polygon(
				eye, eye+[1,0,0], eye+[0,1,0])
		end
	else
		distance = eye.distance(hit[0])
		if distance < distance_min
			distance_min = distance
		end
		if distance > distance_max
			distance_max = distance
		end
		distance_total = distance_total + distance
		distance_n = distance_n + 1

		if @@debug
			mesh.add_polygon(
				eye, hit[0], eye+[0,1,0]
			)
		end

	end
	distancemap[y * depthmap_width + x] = distance

	x = x + 1
end
y = y + 1
end

distance_range = distance_max - distance_min
distance_avg = distance_total / distance_n
#initial_depth = distance_range * 10 / 100
distance_offset =

#distance_avg_towards_camera_direction = camera.direction.clone
#distance_avg_towards_camera_direction.length = distance_avg
#model_height = view.pixels_to_model(
#	view.vpheight,
#	camera.eye + distance_avg_towards_camera_direction)

i = 0
while i < depthmap_width * depthmap_height
	# min stretch to 0.6?
	# max stretch to 10?
	distance = distancemap[i]
	
	if distance < 0 then
		distance = 1.1 * distance_max
	end


#	depthmap[i] = distance / model_height * @@distance_k
	depthmap[i] = 0.6 + (distance - distance_min) / distance_range * @@distance_k
	#puts "#{depthmap[i]}=#{distance} / #{model_height} * #{@@distance_k}"
	i = i + 1
end

if @@debug
	materials = model.materials
	f_material = materials.add('Debug')
	f_material.texture = 'black'
	b_material = f_material

	group = model.entities.add_group
	group.entities.fill_from_mesh(mesh, false, 0, f_material, b_material)
#	UI.messagebox("filled"+mesh.points.to_s)
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

#view.camera = Sketchup::Camera.new old_camera.eye, old_camera.target, old_camera.xaxis.reverse, false

  keys = {
    :filename => File.expand_path("poster.jpg",folder),
    :width => camera_width,
    :height => camera_height,
    :antialias => true,
    :transparent => false
  }
  view.write_image keys

#view.camera = old_camera

UI.messagebox "Exported to " + folder
	end

	def self.prepare
		c = Sketchup.active_model.active_view.camera
		Sketchup.active_model.active_view.camera = Sketchup::Camera.new c.eye, c.direction, c.up
	end

	def self.closer
		c = Sketchup.active_model.active_view.camera
		forward = c.direction
		forward.length = 10000
		Sketchup.active_model.active_view.camera = Sketchup::Camera.new c.eye + forward,c.direction,c.up
	end

	def self.away
		c = Sketchup.active_model.active_view.camera
		backward = c.direction.reverse
		backward .length = 100000
		Sketchup.active_model.active_view.camera = Sketchup::Camera.new c.eye + backward,c.direction,c.up
	end

end

unless file_loaded?(__FILE__)
	UI.menu("Plugins").add_item("Closer") { SeeneExporter.closer }
	UI.menu("Plugins").add_item("Away") { SeeneExporter.away }
	UI.menu("Plugins").add_item("Reset camera zoom") { SeeneExporter.prepare }
	UI.menu("Plugins").add_item("Export Seene...") { SeeneExporter.export }
end

file_loaded(__FILE__)

#UI.messagebox("hi")
