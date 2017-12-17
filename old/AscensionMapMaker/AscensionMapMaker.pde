
final int buffer = 20;
final int baseTileColor = 35;
final String fileExtension = ".txt";
final byte saveLoadShift = 20; //shifts the height data for tiles by an amount because 10 is the keycode for newline

//potential dimensions of hte map
int mapWidth = 25;
int mapHeight = 55;

//tile sets on any layer
byte[][] lowTiles;
byte[][] midTiles;
byte[][] highTiles;

//array of objects added to the set
//highest 3 bits are for player, last 5 are for object type
byte[][] lowItemTiles;
byte[][] midItemTiles;
byte[][] highItemTiles;

byte currDrawHeight = -1;
byte currObject = -1;
byte currPlayer = 0;

boolean setHeightState = true;

int currLayer = 0;

float brushSize = 0;

String cmdline = "";

class TileObjects{
  final public static byte None = 0;
  final public static byte Spawner = 1;
  final public static byte Shrine = 2;
  final public static byte Temple = 3;
  final public static byte Obelisk = 4;
  final public static byte Soul = 5;
  
  final public static byte Tree = 6;
  final public static byte SurfaceFragment = 7;
  final public static byte FoundationTile = 8;
}

//colors used to indicate player colors
color[] playerColors =
  {
    color(244,52,8),     //0 red
    color(71,160,135),     //1 teal
    color(38,71,190),     //2 blue
    color(255,204,43),   //3 yellow
    color(127,193,50),   //4 cyan
    color(113,32,82),   //5 magenta
    
    color(255,255,255), //6 white
    color(0,0,0)        //7 black
  }
;
//two maps:
//one for height, one for objects / items

void setup()
{
  print((int)'\n');
  
  //basic setup
  size(925,700);
  smooth();

  lowTiles = new byte[mapWidth][mapHeight];
  midTiles = new byte[mapWidth][mapHeight];
  highTiles = new byte[mapWidth][mapHeight];
  lowItemTiles = new byte[mapWidth][mapHeight];
  midItemTiles = new byte[mapWidth][mapHeight];
  highItemTiles = new byte[mapWidth][mapHeight];
  
  for(int i = 0 ; i < mapWidth ; i ++)
  {
    for(int j = 0 ; j < mapHeight ; j ++)
    {
      lowTiles[i][j] = -1;
      midTiles[i][j] = -1;
      highTiles[i][j] = -1;
      
      lowItemTiles[i][j] = 0;
      midItemTiles[i][j] = 0;
      highItemTiles[i][j] = 0;
    }
  }
  
}

void draw()
{
  //reset the screen
  background(15, 12, 25);

  byte[][] tileLvl = lowTiles;
  byte[][] tileItem = lowItemTiles;

  switch(currLayer)
  {
    case 0:
      tileLvl = lowTiles;
      tileItem = lowItemTiles;
      break;
    case 1:
      tileLvl = midTiles;
      tileItem = midItemTiles;
      break;
    case 2:
      tileLvl = highTiles;
      tileItem = highItemTiles;
      break;
  }

  //radius of the hexes
  int rad = 12;
  
  //draw the hexagons
  for(int i = 0 ; i < mapWidth ; i ++)
  {
    for(int j = 0 ; j < mapHeight ; j ++)
    {
      //place the hexagons
      float x = buffer + i * rad * 3 + rad * (j % 2) * 1.5;
      float y = buffer + j * rad * .9;
      
      //prepare the color for the tile
      color col = GetTileColor(i,j,tileLvl);
      stroke(30, 24, 50,255);
      strokeWeight(.5f);
      fill(col);

      
      //if the mouse is in the hex hotspot
      if(MouseInHex(x,y,rad)){
        OnHexHover(i,j,tileLvl,tileItem);
      }

      
      DrawHex(x,y,rad);
      DrawItem(x,y, tileItem[i][j]);
    }
  }
  DrawGUI();
}

//draws a hexagon at the given point
void DrawHex(float x, float y, float r)
{
  float offset = 30;
  beginShape();
  for(int i = 0 ; i < 7 ; i ++)
  {
    vertex( x + sin((i*60 + offset)*2*PI/360)*r, y + cos((i*60 + offset)*2*PI/360)*r);
  }
  endShape();
}

//draws the item icon on the appropriate tile
void DrawItem(float x, float y, byte val)
{
  final byte playerMask = -32; // 11100000
  final byte itemMask = 31;    // 00011111
  
  byte player = (byte)(((val & playerMask) >> 5)&7);  //mask val, shift it to the end, and mask it again(for some reason). 7 is 00000111
  byte item = (byte)(val & itemMask); //mask out the item part of the byte
  
  color col = playerColors[ player ];
  fill( col );
  stroke( col );
  
  //if(player == 0) fill(255,0,0);
  
  switch( item )
  {
    case TileObjects.Spawner:
      noStroke();
      ellipse(x,y,13,13);
      break;
    case TileObjects.Shrine:
      rect(x-3,y - 5,4,10); 
      rect(x + 3,y - 1,2,6); 
      break;  
    case TileObjects.Temple:
      rect(x-3,y - 7,4,13); 
      rect(x + 3,y,2,6);
      rect(x - 6,y - 3,1,9);

      break;
    case TileObjects.Obelisk:
      rect(x-3,y - 8,6, 16);
      noFill();
      ellipse( x,y,16,16);
      ellipse( x,y,10,10);
      break;
    case TileObjects.Soul:
      noStroke();
      ellipse(x,y,5,5);
      break;
      
    case TileObjects.Tree:
      strokeWeight(2);
      stroke(13,137,55);
      fill(81,192,20);
      ellipse(x,y,10,10);
      noStroke();
      fill(180,230,29);
      ellipse(x,y,4,4);
      break;
      
    case TileObjects.SurfaceFragment:
      fill(55);
      strokeWeight(1);
      stroke(255);
      ellipse(x,y,10,10);
      ellipse(x,y,6,6);
      break;
    case TileObjects.FoundationTile:
      stroke(255);
      fill(55);
      rect(x - 5, y - 5, 10, 10);
      rect(x - 3, y - 3, 6,6);
  }
}

//returns whether or not the hex is being hovered over
boolean MouseInHex(float x, float y, float r)
{
  float xDist = mouseX - x;
  float yDist = mouseY - y;
  float rad = r * 7/8 + brushSize*4;
  
  float d = dist(x,y, mouseX,mouseY);
  if(d < rad) return true;
  
  
  return false;
}

//fired while the hexagon is being hovered over
void OnHexHover(int x, int y, byte[][] tileheight, byte[][] tileitems)
{
  if( mousePressed )
  {
    //if chaning height
    if(setHeightState){
      tileheight[x][y] = currDrawHeight;
      if(currDrawHeight == -1) tileitems[x][y] = getItemPlayerByte((byte)0, (byte) 0);
    }
    //if adding item / object
    else{
      if(tileheight[x][y] != -1) tileitems[x][y] = getItemPlayerByte(currPlayer, currObject);
      else tileitems[x][y] = getItemPlayerByte((byte)0,(byte)0);
    }
  }
  fill(255,0,0);
}

//returns the color that the tile should be drawn as
color GetTileColor(int x, int y, byte[][] a)
{
  if( a[x][y] == -1 )
  {
    return color(255,0,0,0);
  }
  else
  {
    int base =baseTileColor + a[x][y] * 10;
    
    return color(base,base,base);
  }
}

//returns true if the mouse is over the rectangle or not
boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

//draw and handle the GUI elements
void DrawGUI()
{
  //preparation
  int gx = 0;
  int gy = height - 55;
  textAlign(LEFT,LEFT);

  String[] objects = new String[9];
  objects[ TileObjects.None ] = "None";
  objects[ TileObjects.Spawner ] = "Spawner";
  objects[ TileObjects.Shrine ] = "Shrine";
  objects[ TileObjects.Temple ] = "Temple";
  objects[ TileObjects.Obelisk ] = "Obelisk";
  objects[ TileObjects.Soul ] = "Soul";
  
  objects[ TileObjects.Tree ] = "Tree";
  objects[ TileObjects.SurfaceFragment ] = "SurfaceFragment";
  objects[ TileObjects.FoundationTile ] = "FoundationTile";
  
  //draw background for GUI
  noStroke();
  fill(200);
  rect(gx, gy, width, 55);
  
  strokeWeight(1);
  stroke(0);
  //draw the indicator for which layer is being editted
  for(int i = 0 ; i < 3 ; i ++)
  {
    fill( (2-i == currLayer)?color(255,0,0):200 );
    rect(550 + gx, gy + 12*i + 5, 25, 10);
  }
  
  //draw the current color player being used
  fill(playerColors[currPlayer]);
  text("Player Color: " + currPlayer, 580 + gx, gy + 1, 100, 15);
  
  //draw the current tile height being used
  fill(0);
  if(setHeightState)
  {
    text("Tile Height: " + currDrawHeight, 580 + gx, gy + 18, 150, 15);
  }
  //draw the current object being used
  else
  {
    text("Object: " + objects[currObject], 580 + gx, gy + 18, 150, 15); 
  }

  text("Brush Size: " + brushSize, 580 + gx, gy + 38, 150, 15); 
    
  textAlign(CENTER,CENTER);
 
  //draw buttons to select the the tile height
  for(byte i = 0 ; i <= 20 ; i ++)
  {
    fill(baseTileColor + 10 * i);
    
    if(overRect( gx + 5 + 25*i, gy + 5, 20,20))
    {
      strokeWeight(1);
      stroke(255,0,0);
      if(mousePressed){
        setHeightState = true;
        currDrawHeight = i;
      }
    }
    else
    {
      noStroke();
    }
    
    rect( gx + 5 + 25*i, gy + 5, 20,20);
    
    fill(255);
    text( ""+(i-10), gx + 5 + 25*i, gy + 3,23,20);
  }
  
  noStroke();
  //draw delete button for the tiles
  if(overRect( gx + 5 + 25*21, gy + 5, 20,20)){
    stroke(255,0,0);
    strokeWeight(1);
    if(mousePressed){
      setHeightState = true;
      currDrawHeight = -1;
    }
  }
  fill(255, 100,100);
  rect( gx + 5 + 25*21, gy + 5, 20,20);
  fill( 255,0,0);
  text( "X", gx + 5 + 25*21, gy + 3,20,20);

  //Draw buttons for tile objects  
  for(int i = 0 ; i < objects.length ; i ++)
  {
    int w = 50;
    fill(255);
    //draw delete button for the tiles
    if(overRect( gx + 5 + (w + 5)*i, gy + 30, w,20)){
      stroke(255,0,0);
      strokeWeight(1);
      if(mousePressed){
        setHeightState = false;
        currObject = (byte)i;
      }
    }else{
      noStroke();
    }
    rect( gx + 5 + (w + 5)*i, gy + 30, w,20);
    
    fill(0);
    text( objects[i], gx + 5 + (w + 5)*i, gy + 30,w,20);
  }
  
  
  textAlign(LEFT,LEFT);
  text(cmdline,gx + 675, gy + 3, 200, 15);
  
}

//returns the byte needed to store the player and object
byte getItemPlayerByte(byte player, byte item)
{
  return (byte)((byte)(player << 5) + (byte)item);
}

//called when a key is pressed
void keyPressed(){
  
  switch( key )
  {
    case 'W':
      currLayer ++;
      break;
    case 'S':
      currLayer --;
      break;
    case 'A':
      brushSize -= 1;
      break;
    case 'D':
      brushSize += 1;
      break;
  }
  switch( keyCode )
  {
    case UP:
      currLayer ++;
      break;
    case DOWN:
      currLayer --;
      break;
    case LEFT:
      brushSize -= 1;
      break;
    case RIGHT:
      brushSize += 1;
      break;
  }
  //adjust brushsize
  if(brushSize < 0) brushSize = 0;
  
  //adjust layer
  if( currLayer < 0 ) currLayer = 2;
  currLayer %= 3;
  
  if( key >= '0' && key <= '9'){
    int num = (int)key - (int)'0';
    if( num > 0 ) num -=1;
    currPlayer = (byte)num;
  }
  currPlayer %= 8;
 
  if( key == 'C' ) ClearMap();
  
  if( ((int)key >='a' && (int)key <= 'z') || key == ' '){
    cmdline += key;
  }
  else if( keyCode == DELETE || keyCode == BACKSPACE)
  {
    if(cmdline.length() > 0) cmdline = cmdline.substring(0, cmdline.length() - 1);
  }
  else if( keyCode == ENTER )
  {
    ParseCommand( cmdline );
    cmdline = "";
  }
}

//save the map to an image file
void SaveOut(String name)
{
  //find the bounds of the level
  int minX = mapWidth - 1;
  int maxX = 0;
  int minY = mapHeight - 1;
  int maxY = 0;
  
  for(int y = 0 ; y < mapHeight ; y ++)
  {
    for(int x = 0 ; x < mapWidth ; x ++)
    {
      if(
        lowTiles[x][y] != -1 ||
        midTiles[x][y] != -1 ||
        highTiles[x][y] != -1
      )
      {
        if( x < minX ) minX = x;
        if( x > maxX ) maxX = x;
        if( y < minY ) minY = y;
        if( y > maxY ) maxY = y;
      }
    }
  }
  
  String s[] = {"","",""};
  String header = "head:" + 
    ((minY % 2 == 1)? "oddstart|" : "")
  ;
  
  println("minX : " + minX + " minY : " + minY);
  
  for(int y = minY ; y <= maxY ; y ++)
  {
    for(int x = minX ; x <= maxX ; x ++)
    {
      byte tile = lowTiles[x][y];
      s[0] += (char)(tile + saveLoadShift);
      if(tile != -1) s[0] += (char)lowItemTiles[x][y];
      
      tile = midTiles[x][y];
      s[1] += (char)(tile + saveLoadShift);
      if(tile != -1) s[1] += (char)midItemTiles[x][y];
      
      tile = highTiles[x][y];
      s[2] += (char)(tile + saveLoadShift);
      if(tile != -1) s[2] += (char)highItemTiles[x][y];
    }
    s[0] += '\n';
    s[1] += '\n';
    s[2] += '\n';
  }  
  
  //header = "";
  String lvlString = s[0] + s[1] + s[2] + header;
  
  if( maxX - minX <= 0 || maxY - minY <= 0 ){
    println("No map to save, save failed");
    return;
  }
  
  String[] saveStr = {lvlString};
  saveStrings("/maps/" + name + fileExtension, saveStr);
  
  LoadIn(name + fileExtension);
}

void LoadIn(String file)
{
  ClearMap();
  
  //get the lvl into a string
  String lvlString = "";
  
  String[] loadedStrings = loadStrings("../maps/" + file);
  for(int i = 0 ; i < loadedStrings.length ; i ++)
  {
    lvlString += loadedStrings[i] + '\n';
  }
  
  print(lvlString);
  
  //split it across the newlines
  String[] spl = lvlString.split("\n");
  
  
  //handle the headers
  boolean headerLine = false;
  boolean oddStart = false; //whether the map begins on an oddStart line or not
  if( spl[spl.length - 1].indexOf("head:") != -1)
  {
    String header = spl[spl.length - 1];
    headerLine = true;
    if( header.indexOf("oddstart") != -1 ) oddStart = true;
  }
  
  //state whether to look for a tile or object
  boolean lookForTile = true;
  
  //calculate the supposed height and width
  int loadedMapHeight = (spl.length - ((headerLine)?1:0))/3;
    
  //count the amount of tiles per line
  int loadedMapWidth = 0;
  for(int i = 0 ; i < spl[0].length() ; i ++)
  {
    //if expecting a tile
    if(lookForTile)
    {
      if( (byte)spl[0].charAt(i) == -1+saveLoadShift ) loadedMapWidth ++;
      else lookForTile = false;
    }
    //otherwise if expecting an object
    else
    {
      loadedMapWidth ++;
      lookForTile = true;
    }
  }
  
  println(loadedMapWidth + " : " + loadedMapHeight);
  
  if(loadedMapWidth <= 0 || loadedMapHeight <= 0){
    println("No map to load, load failed");
    return;
  }
  
  lookForTile = true;
  //calculate the buffer on the left and right to load the map in the center
  int bufferTop = (mapHeight - loadedMapHeight)/2;
  int bufferLeft = (mapWidth - loadedMapWidth)/2;
  bufferTop -= (bufferTop%2);
  
  bufferTop = bufferTop+ ((oddStart && bufferTop%2 == 0)?1:0);
  //bufferLeft = 0;
  
  int newlineCount = 0; //total amount of newline characters
  int tileOnLine = 0; // amount of tiles found on the line so far
  
  for( int i = 0; i < lvlString.length() ; i ++)
  {
    char c = lvlString.charAt(i);
    if( c == '\n'){
      newlineCount ++;
      tileOnLine = 0;
      
      continue;
    }
    
    int layer = (int)((newlineCount) / loadedMapHeight);
    if(layer > 2) break;
    
    byte[][] tiles = lowTiles;
    byte[][] objs = lowItemTiles;
    switch(layer)
    {
      case 0:
        tiles = lowTiles;
        objs = lowItemTiles;
        break;
      case 1:
        tiles = midTiles;
        objs = midItemTiles;
        break;
      case 2:
        tiles = highTiles;
        objs = highItemTiles;
        break;
    }
    
    int x = tileOnLine;
    int y = newlineCount - layer * loadedMapHeight;
    
    
    if(lookForTile)
    {
      tiles[x + bufferLeft][y + bufferTop] = (byte)((byte)c - (byte)saveLoadShift);
      
      if( (byte) c != -1+saveLoadShift ) lookForTile = false;
      else tileOnLine ++;
    }
    else
    {
      objs[x + bufferLeft][y + bufferTop] = (byte) c;
      lookForTile = true;
      tileOnLine ++;
    }
  }
  
  println("loaded");
}

//clears the map
void ClearMap()
{
  //clean the current map
  for(int y = 0 ; y < mapHeight ; y ++)
  {
    for(int x = 0 ; x < mapWidth ; x ++)
    {
      lowTiles[x][y] = -1;
      midTiles[x][y] = -1;
      highTiles[x][y] = -1;
      
      lowItemTiles[x][y] = TileObjects.None;
      midItemTiles[x][y] = TileObjects.None;
      highItemTiles[x][y] = TileObjects.None;
      
    }
  }
}

//takes the given string and uses it as a command
void ParseCommand(String s)
{
  String[] spl = s.split(" ");
  
  if(spl.length != 2) return;
  
  String cmd = spl[0];
  String name = spl[1];
      
  if( cmd.equals("save") )
  {
    SaveOut(name);
  }
  else if( cmd.equals("load"))
  {
    LoadIn(name + fileExtension);
  }
}
