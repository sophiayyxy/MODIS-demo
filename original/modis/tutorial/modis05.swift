type file;
type imagefile;
type landuse;
type getland_script;
type analyze_script;
type markmap_script;
type color_script;


app (landuse output) getLandUse (imagefile input, getland_script script)
{
  bash filename(script) filename(input) stdout=filename(output);
}

app (file output, file tilelist) analyzeLandUse (landuse input[], string usetype, int maxnum, analyze_script script)
{
  bash filename(script) @output @tilelist usetype maxnum @input;
}

app (imagefile grid) markMap (file tilelist, markmap_script script) 
{
  bash filename(script) @tilelist @grid;
}

app (imagefile output) colorModis (imagefile input, color_script script)
{
  bash filename(script) @input @output;
}

# Constants and command line arguments
int nFiles       = toInt(arg("nfiles", "1000"));
int nSelect      = toInt(arg("nselect", "10"));
string landType  = arg("landtype", "urban");
string MODISdir  = arg("modisdir", "../data");

# Input Dataset
imagefile geos[] <ext; exec="../bin/modis.mapper", location=MODISdir, suffix=".rgb", n=nFiles>;

# Compute the land use summary of each MODIS tile
landuse land[] <structured_regexp_mapper; source=geos, match="(h..v..)", transform=strcat("landuse/\\1.landuse5.byfreq")>;

getland_script getland<"../bin/getlanduse.sh">;
analyze_script analyze<"../bin/analyzelanduse.sh">;
markmap_script markmap<"../bin/markmap.sh">;
color_script colormodis<"../bin/colormodis.sh">;

foreach g,i in geos {
    land[i] = getLandUse(g, getland);
}

# Find the top N tiles (by total area of selected landuse types)
file topSelected <"topselected.txt">;
file selectedTiles <"selectedtiles.txt">;
(topSelected, selectedTiles) = analyzeLandUse(land, landType, nSelect, analyze);

# Mark the top N tiles on a sinusoidal gridded map
imagefile gridmap <"gridmap.png">;
gridmap = markMap(topSelected, markmap);

# Create multi-color images for all tiles
imagefile colorImage[] <structured_regexp_mapper; source=geos, match="(h..v..)", transform=strcat("colorImages/\\1.color.rgb")>;

foreach g, i in geos {
  colorImage[i] = colorModis(g, colormodis);
}
