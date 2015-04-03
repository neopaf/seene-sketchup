#
# Importer plugin for Sketchup, loads scene.oemodel and texturizes it with poster.jpg (
# see https://github.com/neopaf/seene-backup to get them)
#
# Copyright 2014 Alexander Petrossian (PAF) alexander.petrossian+seene.rb@gmail.com
#
# https://github.com/neopaf/seene-backup
#



# Copyright 2004-2005, Todd Burch - Burchwood USA   http://www.burchwoodusa.com

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# Name :          progressbar.rb 1.0
# Description :   Creates a text-based progress bar on the status line.
# Author :        Todd Burch   http://www.burchwoodusa.com 
# Usage :         1. to create a progress bar from your script: 
#
#                 pb = ProgressBar.new(total_items_to_process{,optional_process_name}) 
#
#                 To update the status bar: 
#
#                 pb.update(current_item_number_being_processed)  
#
#                
# Date :          11.Nov.2005
# Type :          Module 
# History:        1.0 (11.Nov.2005) - first version
#
#
#-----------------------------------------------------------------------------

class ProgressBar 

@@err_total_notnumeric = "ProgressBar: Total must be a positive integer."
@@err_count_notnumeric = "ProgressBar: Iteration Count must be numeric"
@@end_time             = "Expected End Time:" 
@@progresschar = ">" ; 
@@initial_block = "-" * 50     # Default progress bar line sequence.

def initialize(total,phase=nil)  
  if (!total.integer? or total < 0)
    raise(ArgumentError,@@err_total_notnumeric) 
    return ; 
    end ; 
  @total = total.to_i ; 
  @phase = phase ; 
  @firsttime = true ; 
  end ; 

def update(iteration) 
  if !iteration.integer? 
    raise(ArgumentError,@@err_count_notnumeric)  
    return ; 
    end ; 
  iteration = [iteration.abs,@total].min  # make sure we don't exceed the total count or have a value < 0
  pct = [1,(iteration*100)/@total].max    # Calculate percentage complete.
                                          # round up to 1% if anything less than 1%.
  end_time = "?" ; 
  if @firsttime then ; 
    # Get the current time of day. 
    # set up an elapsed timer so we can calculate expected end time.  
    @time1 = Time.now ;     # Get current time of day. 
    @firsttime = false ;    # turn off switch 
  else 
    # divide the elapsed time by the pct complete, then multiple that by 100, then add that to the 
    # start time, and that is the expected end time.  
    end_time = Time.at(((((Time.now-@time1).to_f)/pct)*100 + @time1.to_f).to_i).strftime("%c") 
    end ; 
  pct_pos = [pct/2,1].max ;
  current_block = @@initial_block[0,pct_pos-1] << @@progresschar << @@initial_block[pct_pos,@@initial_block.length]
  Sketchup.set_status_text(current_block << "   " << (pct.to_s)<<"%. #{@@end_time} " << end_time <<" #{@phase}")
  end ; 

end ; # class ProgressBar ; 

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
       @@skip = 3
       def do_options
         # In a real use you would probably store this information in an
         # instance variable.
         my_settings = UI.inputbox(['0=slow 3=fast'], [@@skip.to_s],
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
		status = model.start_operation('Import Seene', true)
		result = load_file_internal(file_path, status)
		model.commit_operation
		return result
       end
 
       def load_file_internal(file_path, status)
 begin

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

pb = ProgressBar.new(depthmap_height-2, "Making faces... (will hang at about 97%, wait a few minutes)")
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
pb.update(y)
y = y + block_size
end


model = Sketchup.active_model
group = model.entities.add_group

materials = model.materials
f_material = materials.add('Front')
f_material.texture = File.expand_path("poster.jpg",folder)
b_material = materials.add('Back')
b_material.texture = 'black'

#first_point = v(0, 0, depthmap,depthmap_width,depthmap_height)
last_point = v(depthmap_width-block_size, depthmap_height-block_size, depthmap,depthmap_width,depthmap_height)
#f_material.texture.size = last_point.x - first_point.x
f_material.texture.size = last_point.x
smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN

pb = ProgressBar.new(1, "Adding faces (slow)")
group.entities.add_faces_from_mesh mesh, smooth_flags, f_material, f_material

pb = ProgressBar.new(1, "Setting projection properties")
vector_down = Geom::Vector3d.new 0,0,1
group.entities.each { |entity|
	if entity.is_a? Sketchup::Face
		entity.set_texture_projection(vector_down,true)
		entity.set_texture_projection(vector_down,false)
		entity.casts_shadows = false
	end
}

pb = ProgressBar.new(1, "Moving camera")

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

pb = ProgressBar.new(1, "Done")

rescue Exception => e
  UI.messagebox "Import failed: " + e.to_s + "\n" + e.backtrace
  raise #to display the problem in ruby console as well (should be open)
end
         return 0 # 0 is the code for a successful import
       end
     end

     Sketchup.register_importer(SeeneImporter.new)
#UI.messagebox("hi")

