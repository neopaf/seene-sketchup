# seene-sketchup
Importer plugin for Sketchup, loads scene.oemodel and texturizes it with poster.jpg  (see seene-backup to get them)

# install

Install Sketchup from http://www.sketchup.com

Put [file](seene.rb) to your Sketchup plugins directory
* Mac: /Users/<your user name>/Library/Application Support/SketchUp 2015/SketchUp/Plugins
* Windows: C:\Program Files (x86)\SketchUp\SketchUp 2015\Plugins

# Use

0. Download some Seenes using https://github.com/neopaf/seene-backup (or use sample files below)
1. Start Sketchup
2. File|New
3. File|Import...
4. Format: Seene (*.oemodel)
5. Pick scene.oemodel you want to import (poster.jpg should be in same folder with it)
6. Click Import
7. Wait around 5 minutes
8. Be happy
9. Be creative. Combine several Seene-views of one object together or make lots of Seenes in a room and put it in a room in 3D, publish result somewhere.

# Known issues

Does NOT work fast with new models of 240x240 scene.oemodel; working on it... maybe will add an option to reduce the depth model granularity on import.

For now: 
* old Seenes importL 15 seconds
* new Seenes import: 5 minutes

Progress indicator shows only what it can; most is done in one action without callback hooks, so can not show it (yet?). All ideas are welcome.

# Sample files

[poster.jpg](samples/paf-first-staffpick/poster.jpg)

[scene.oemodel](samples/paf-first-staffpick/scene.oemodel)
