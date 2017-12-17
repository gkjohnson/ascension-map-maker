//radius of the hexes
final int HEX_RADIUS = 12;

final int buffer = 20;
final int baseTileColor = 35;
final String fileExtension = ".bytes";
final byte saveLoadShift = 20; //shifts the height data for tiles by an amount because 10 is the keycode for newline

//potential dimensions of hte map
int mapWidth = 30;
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

//arrays used for the surface fragments
byte[][] lowSurfTiles;
byte[][] midSurfTiles;
byte[][] highSurfTiles;

byte currDrawHeight = 10;
byte currObject = -1;
byte currPlayer = 0;
byte currSurf = 0;

final int SET_HEIGHT = 0;
final int SET_UNIT = 1;
final int SET_SURF = 2;
int drawState = SET_HEIGHT;

int currLayer = 0;

float brushSize = 0;

String cmdline = "";

class TileUnits{
  final public static byte None = 0;
  final public static byte Spawner = 1;
  final public static byte Shrine = 2;
  final public static byte Temple = 3;
  final public static byte Obelisk = 4;
  final public static byte Soul = 5;
}
class SurfaceFragments{
  final public static byte None = 0;
  final public static byte Tree = 1;
  final public static byte SurfaceFragment = 2;
  final public static byte FoundationTile = 3;  
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
  //basic setup
  size(1100,700);
  smooth();

  lowTiles = new byte[mapWidth][mapHeight];
  midTiles = new byte[mapWidth][mapHeight];
  highTiles = new byte[mapWidth][mapHeight];
  
  lowItemTiles = new byte[mapWidth][mapHeight];
  midItemTiles = new byte[mapWidth][mapHeight];
  highItemTiles = new byte[mapWidth][mapHeight];
  
  lowSurfTiles = new byte[mapWidth][mapHeight];
  midSurfTiles = new byte[mapWidth][mapHeight];
  highSurfTiles = new byte[mapWidth][mapHeight];
  
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
  byte[][] tileSurf = lowSurfTiles;
  
  switch(currLayer)
  {
    case 0:
      tileLvl = lowTiles;
      tileItem = lowItemTiles;
      tileSurf = lowSurfTiles;
      break;
    case 1:
      tileLvl = midTiles;
      tileItem = midItemTiles;
      tileSurf = midSurfTiles;
      break;
    case 2:
      tileLvl = highTiles;
      tileItem = highItemTiles;
      tileSurf = highSurfTiles;
      break;
  }
  
  int rad = HEX_RADIUS;
  
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
        OnHexHover(i,j,tileLvl,tileItem, tileSurf);
      }

      
      DrawHex(x,y,rad);
      DrawSurf(x,y, tileSurf[i][j]);
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
  if( val == TileUnits.None ) return;
  
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
    case TileUnits.Spawner:
      noStroke();
      ellipse(x,y,13,13);
      break;
    case TileUnits.Shrine:
      rect(x-3,y - 5,4,10); 
      rect(x + 3,y - 1,2,6); 
      break;  
    case TileUnits.Temple:
      rect(x-3,y - 7,4,13); 
      rect(x + 3,y,2,6);
      rect(x - 6,y - 3,1,9);

      break;
    case TileUnits.Obelisk:
      rect(x-3,y - 8,6, 16);
      noFill();
      ellipse( x,y,16,16);
      ellipse( x,y,10,10);
      break;
    case TileUnits.Soul:
      noStroke();
      ellipse(x,y,5,5);
      break;
  }
}

void DrawSurf(float x, float y, byte val)
{
  if( val == SurfaceFragments.None ) return;
  
  switch( val )
  {
    case SurfaceFragments.FoundationTile:
      fill(30,30,30);
      stroke(0,0,0);
      strokeWeight(1);
      DrawHex(x,y,HEX_RADIUS - 4);
      break;
    case SurfaceFragments.Tree:
      fill(150,255,50);
      noStroke();
      ellipse(x-4, y-4, 10,10);
      break;
    case SurfaceFragments.SurfaceFragment:
      fill(255);
      stroke(0);
      strokeWeight(1);
      ellipse(x,y,10,10);
      line(x + 4, y + 4, x - 4, y -4);
      break;
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
void OnHexHover(int x, int y, byte[][] tileheight, byte[][] tileitems, byte[][] tileSurf)
{
  if( mousePressed )
  {
    //if chaning height
    if(drawState == SET_HEIGHT){
      tileheight[x][y] = currDrawHeight;
      if(currDrawHeight == -1){
        tileitems[x][y] = getItemPlayerByte((byte)0, (byte) 0);
        tileSurf[x][y] = SurfaceFragments.None;
      }
    }
    //if adding item / object
    else if (drawState == SET_UNIT){
      if(tileheight[x][y] != -1) tileitems[x][y] = getItemPlayerByte(currPlayer, currObject);
      else tileitems[x][y] = getItemPlayerByte((byte)0,(byte)0);
    }
    else if(drawState == SET_SURF)
    {
      if(tileheight[x][y] != -1) tileSurf[x][y] = currSurf;
      else tileSurf[x][y] = SurfaceFragments.None;
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

  String[] objects = new String[6];
  objects[ TileUnits.None ] = "None";
  objects[ TileUnits.Spawner ] = "Spawner";
  objects[ TileUnits.Shrine ] = "Shrine";
  objects[ TileUnits.Temple ] = "Temple";
  objects[ TileUnits.Obelisk ] = "Obelisk";
  objects[ TileUnits.Soul ] = "Soul";

  String[] surfs = new String[4];
  surfs[ SurfaceFragments.None ] = "None";
  surfs[ SurfaceFragments.FoundationTile ] = "Foundation";
  surfs[ SurfaceFragments.Tree ] = "Tree";
  surfs[ SurfaceFragments.SurfaceFragment ] = "SurfaceFrag";
  
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
    rect(700 + gx, gy + 12*i + 5, 25, 10);
  }
  
  //draw the current color player being used
  fill(playerColors[currPlayer]);
  text("Player Color: " + currPlayer, 730 + gx, gy + 1, 100, 15);
  
  //draw the current tile height being used
  fill(0);
  if(drawState == SET_HEIGHT)
  {
    text("Tile Height: " + currDrawHeight, 730 + gx, gy + 18, 150, 15);
  }
  //draw the current object being used
  else if( drawState == SET_UNIT)
  {
    text("Object: " + objects[currObject], 730 + gx, gy + 18, 150, 15); 
  }
  else if( drawState == SET_SURF)
  {
    text("SurfFrag: " + surfs[currSurf], 730 + gx, gy + 18, 150, 15 );
  }
  text("Brush Size: " + brushSize, 730 + gx, gy + 38, 150, 15); 
    
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
        drawState = SET_HEIGHT;
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
      drawState = SET_HEIGHT;
      currDrawHeight = -1;
    }
  }
  fill(255, 100,100);
  rect( gx + 5 + 25*21, gy + 5, 20,20);
  fill( 255,0,0);
  text( "X", gx + 5 + 25*21, gy + 3,20,20);


  int pos = 0;
  //Draw buttons for tile objects  
  for(int i = 0 ; i < objects.length ; i ++)
  {
    int w = 50;
    fill(255);
    //draw delete button for the tiles
    if(overRect( gx + 5 + (w + 5)*pos, gy + 30, w,20)){
      stroke(255,0,0);
      strokeWeight(1);
      if(mousePressed){
        drawState = SET_UNIT;
        currObject = (byte)i;
      }
    }else{
      noStroke();
    }
    rect( gx + 5 + (w + 5)*pos, gy + 30, w,20);
  
    fill(0);
    text( objects[i], gx + 5 + (w + 5)*pos, gy + 30,w,20);
    pos++;
  }
  
  pos = 0;
  //Draw the surface fragment boxes
  for(int i = 0 ; i < surfs.length ; i ++)
  {
    int w = 50;
    fill(200,200,255);
    if( overRect( gx + 400 + (w + 5)*pos, gy+30,w,20) )
    {
      stroke(255,0,0);
      strokeWeight(1);
      if(mousePressed)
      {
        drawState = SET_SURF;
        currSurf = (byte) i;
      }
    }
    else
    {
      noStroke();
    }
    rect( gx + 400 + (w + 5)*pos, gy+30,w,20) ;
    fill(0);
    text( surfs[i], gx + 400 + (w + 5)*pos, gy+30,w,20) ;
    pos ++;
  }
  
  textAlign(LEFT,LEFT);
  text(cmdline,gx + 830, gy + 3, 200, 15);
  
}

//returns the byte needed to store the player and object
byte getItemPlayerByte(byte player, byte item)
{
  return (byte)((byte)(player << 5) + (byte)item);
}

//called when a key is pressed
void keyPressed(){
  
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
  
  if( ((int)key >='a' && (int)key <= 'z') || key == ' ' || key=='.'){
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
      
      lowItemTiles[x][y] = TileUnits.None;
      midItemTiles[x][y] = TileUnits.None;
      highItemTiles[x][y] = TileUnits.None;
     
      lowSurfTiles[x][y] = SurfaceFragments.None;
      midSurfTiles[x][y] = SurfaceFragments.None;
      highSurfTiles[x][y] = SurfaceFragments.None;
      
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