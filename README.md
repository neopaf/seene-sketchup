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
5a. Click Options... to set import quality: 0=best, slowest; default=3 (poor, fast)
6. Click Import
7. Wait around 5 seconds for default quality 
7a. or 1 minute for best quality, application will totally lock up and not update its screen, that's normal
8. Be happy
9. Be creative. Combine several Seene-views of one object together or make lots of Seenes in a room and put it in a room in 3D
10. Publish result somewhere
11. Send some feedback to me, [Alexander Petrossian (PAF)](mailto:alexander.petrossian+seene.rb@gmail.com)
12. If see a problem, report it [here](https://github.com/neopaf/seene-sketchup/issues), I'll see what I can do

Happy importing!

# Viewing

Camera|Orbit, hold your Alt key, drag the middle of a Seene around.

If you are lost in rotating, click on 'Scene 1' at the top, to reset camera position.

# Retouching

Recommend the Smooth tool from [Skulpt Tools](http://sketchucation.com/forums/viewtopic.php?t=20781) plugin to fight small bumps.

# Sample files

## paf-first-staffpick

Original: http://seene.co/s/vdYWH4/

[poster.jpg](samples/paf-first-staffpick/poster.jpg)

[scene.oemodel](samples/paf-first-staffpick/scene.oemodel)

After import: [Click to see](samples/paf-first-staffpick/sketchup_imported.png)

## paf-sand-tunnel

Original: http://seene.co/s/sK2Y22

[poster.jpg](samples/paf-sand-tunnel/poster.jpg)

[scene.oemodel](samples/paf-sand-tunnel/scene.oemodel)

After import: [Click to see](samples/paf-sand-tunnel/sketchup_imported.png)

# Thanks

To Creators of Seene app.

To authors of https://github.com/SketchUp/sketchup-stl/blob/master/src/sketchup-stl/importer.rb for two speedup ideas.
