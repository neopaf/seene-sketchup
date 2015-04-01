# seene-sketchup
http://seene.co/ format importer plugin for [Sketchup](http://www.sketchup.com), loads scene.oemodel and texturizes it with poster.jpg  (see [seene-backup](https://github.com/neopaf/seene-backup) to get them)

# Installation

Install [Sketchup](http://www.sketchup.com)

Download .zip file of this repo (button on the right of this page).

Put [seene-sketchup importer plugin file "seene.rb"](seene.rb) to your Sketchup plugins directory
* Mac: /Users/<your user name>/Library/Application Support/SketchUp 2015/SketchUp/Plugins
* Windows: C:\Program Files (x86)\SketchUp\SketchUp 2015\Plugins

# Usage

0. Download some Seenes using https://github.com/neopaf/seene-backup (or use sample files below)
1. Start Sketchup
2. File|New
3. File|Import...
4. Format: Seene (*.oemodel)
5. Pick scene.oemodel you want to import (poster.jpg should be in same folder with it)
6. Click Import
7. Wait around 5 minutes
8. Be happy
9. Be creative. Combine several Seene-views of one object together or make lots of Seenes in a room and put it in a room in 3D
10. Publish result somewhere
11. Send some feedback to me, [Alexander Petrossian (PAF)](mailto:alexander.petrossian+seene.rb@gmail.com)
12. If see a problem, report it on [here](https://github.com/neopaf/seene-sketchup/issues), I'll see what I can do

Happy importing!

# Sample files

## paf-first-staffpick

[poster.jpg](samples/paf-first-staffpick/poster.jpg)

[scene.oemodel](samples/paf-first-staffpick/scene.oemodel)

### Original

http://seene.co/s/vdYWH4/

### After import

[Click to see](samples/paf-first-staffpick/sketchup_imported.png)

# Known issues

Does NOT work fast with new models of 240x240 scene.oemodel; working on it... maybe will add an option to reduce the depth model granularity on import.

For now: 
* old Seenes importL 15 seconds
* new Seenes import: 10 minutes :(

Progress indicator shows only what it can; most is done in one action without callback hooks, so can not show it (yet?). All ideas are welcome.

Quality is low, it looks much better in Seene itself so far. Creators know some Magic. Will learn it...

# Thanks

To Creators of Seene app.
