
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

  int w = maxX - minX + 1;
  int h = maxY - minY + 1;

  String[] header = {
    "VERSION 0.1\n" +
    "WIDTH " + w + "\n" +
    "HEIGHT " + h + "\n" +
    "PLAYERS 0\n" +
    "DATA"
  };
  println("saving : " + w + " : " + h);
  
  byte[] b = new byte[ w * h * 6 * 3 ];
  
  for(int y = 0 ; y < h * 3 ; y ++)
  {
    for(int x = 0 ; x < w ; x ++)
    {
      
      int index = ( y * w + x ) * 6;
      
      int layer = y / h;
      
      byte[][] currTiles = lowTiles;
      byte[][] currUnits = lowItemTiles;
      byte[][] currSurfs = lowSurfTiles;
      switch( layer )
      {
      case 0:
        currTiles = lowTiles;
        currUnits = lowItemTiles;
        currSurfs = lowSurfTiles;
        break;
      case 1:
        currTiles = midTiles;
        currUnits = midItemTiles;
        currSurfs = midSurfTiles;
        break;
      case 2:
        currTiles = highTiles;
        currUnits = highItemTiles;
        currSurfs = highSurfTiles;
        break;
      }
      
      int newY = y % h + minY;
      int newX = x + minX;

      //println(newX + " : " + newY + " - " + (byte)(currTiles[newX][newY] + 1));
      
      
      b[ index ] = (byte)(currTiles[newX][newY] + 1); //orig tile height
      b[ index + 1 ] = (byte)(currTiles[newX][newY] + 1); //current tile richness and height
      b[ index + 2 ] = (byte)(currUnits[newX][newY]) ; //current unit and player
      b[ index + 3 ] = 1 ; //amount of souls on the tile
      b[ index + 4 ] = (byte)currSurfs[newX][newY] ; //surface fragment
      b[ index + 5 ] = 0 ; //internal fragment

    }
  }
  
  // print the header
  for(int i = 0; i < header.length; i ++) {
    println(header[i]);
  }
  
  byte[] headerbytes = loadBytes("header.txt");
  b = concat( headerbytes, b );
  
  saveBytes("/maps/"+name+fileExtension, b);
  
  //LoadIn(name + fileExtension);
  LoadIn(name + fileExtension);
}

void LoadIn(String file)
{
  ClearMap();

  String[] s = loadStrings("/maps/" + file);
  String fullstring = "";
  
  int w = 0;
  int h = 0;
  for( int i = 0 ; i < s.length ; i ++)
  {
    String[] spl = s[i].split(" ");
    if(spl[0] == "DATA") break; 
  
    println( spl[0]);
    if( spl.length > 1) println(" - " + spl[1]);

  
    if(spl[0].equals( "WIDTH" ))
    {
        w = stringToPosInt(spl[1]);
    }
    else if( spl[0].equals( "HEIGHT" ))
    {
        h = stringToPosInt(spl[1]);
    }
    fullstring += s[i] + "\n";
  }
  
  int bufferX = ( mapWidth - w ) / 2;
  int bufferY = ( mapHeight - h ) / 2;

  int dataStart = fullstring.indexOf("\n", fullstring.indexOf("DATA")) + 2;
  
  /*println((byte)fullstring.charAt(fullstring.indexOf("\n", fullstring.indexOf("DATA")) + 0));
  println((byte)fullstring.charAt(fullstring.indexOf("\n", fullstring.indexOf("DATA")) + 1));
  println((byte)fullstring.charAt(fullstring.indexOf("\n", fullstring.indexOf("DATA")) + 2));
  println((byte)fullstring.charAt(fullstring.indexOf("\n", fullstring.indexOf("DATA")) + 3));
  */
  byte[] b = loadBytes("/maps/" + file);
  
  println( w + " : " + h);
  println( "binlen : " + (b.length - dataStart));
  for(int i = dataStart ; i < b.length ; i ++)
  {
    int y = ( i - dataStart) / (6*w);
    int x = ((( i - dataStart) / 6) - y*w) % w;
    int layer = y/h;
    if(layer > 2) break;
    
    println( "i: " + (i - dataStart) + " x: " + x + " y: " + y + " layer: " + layer);
    
    byte[][] t = null;
    byte[][] u = null;
    byte[][] surf = null;
    switch( layer )
    {
      case 0:
        t = lowTiles;
        u = lowItemTiles;
        surf = lowSurfTiles;
        break;
      case 1:
        t = midTiles;
        u = midItemTiles;
        surf = midSurfTiles;
        break;
      case 2:
        t = highTiles;
        u = highItemTiles;
        surf = highSurfTiles;
        break;
    }
    if( b[i] != 0 )
    {
      t[bufferX + x][bufferY + y%h] = (byte)(b[i] - 1); // current item
      u[bufferX + x][bufferY + y%h] = (byte)(b[i + 2]); // unit
      surf[bufferX + x][bufferY + y%h] = (byte)(b[i + 4] & (byte)7);
    }
    
    i += 5;
  }
}

int stringToPosInt(String number){
  int j=0;
  for(int i=0; i < 200; i++){
    String temp = Integer.toString(i);
    if(number.equals(temp)){
	j = i; 
    }
  }
  return j;
} 