//TODO: 
// Block class
// Pattern class
// create the blocks and the pattern and add to array
//       only upon "catalog it!" click
// snap2grid in pattern constructor

// import java dependencies
import java.util.Collections;
import java.util.Comparator;

// import the TUIO library
import TUIO.*;
// declare a TuioProcessing client
TuioProcessing tuioClient;

// these are some helper variables which are used
// to create scalable graphical feedback
float cursor_size = 15;
float object_size = 60;
float table_size = 760;
float scale_factor = 1;
PFont font;

float obj_size = object_size*scale_factor; 
float cur_size = cursor_size*scale_factor; 
  
boolean verbose = false; // print console debug messages
boolean callback = true; // updates only after callbacks

// patterns and blocks stored 
ArrayList<Block> my_blocks = new ArrayList<Block>();
ArrayList<Pattern> my_patterns = new ArrayList<Pattern>();

void setup()
{
  // GUI setup
  //noCursor();
  size(displayWidth/2, 3*displayHeight/4);
  noStroke();
  fill(0);
  
  // periodic updates
  if (!callback) {
    frameRate(60); //<>//
    loop();
  } else noLoop(); // or callback updates 
  
  font = createFont("Arial", 18);
  scale_factor = height/table_size;
  
  
  // finally we create an instance of the TuioProcessing client
  // since we add "this" class as an argument the TuioProcessing class expects
  // an implementation of the TUIO callback methods in this class (see below)
  tuioClient  = new TuioProcessing(this);
  
}

void draw()
{
  background(255);
  textFont(font,18*scale_factor);
  
  // Create workspace boxes and buttons
  makeClickableBox();
  makeCatalogSpace();
  
  // Set tuoi parameters to be fiducial-length rectangles
  resizeTuios();
  
  // If box is clicked, catalog the pattern!
  catalogIfClicked();
  
  // updates window with stored patterns
  for (int i = 0; i < my_patterns.size(); i++){
    int xpos = width - 10 - 20 * (i + 1);
    int ypos = 15;
    my_patterns.get(i).drawPattern(xpos,ypos,10);
  }
    
 
   
}


// --------------------------------------------------------------
////** HELPER FUNCTIONS **////
// --------------------------------------------------------------

// make clickable box
void makeClickableBox(){
  fill(20,50,100,50);
  rect(10,10,155,40);
  textSize(32);
  fill(0, 102, 153);
  text("Catalog it!",15,40);
}

// Create the box in which myPatterns are stored!
void makeCatalogSpace(){
  fill(100,0,250,50);
  rect(width-10-155,10,155,60);
  textSize(12);
  fill(60, 0, 20);
  text("My Patterns",width-120,10);
}

// Make tuios appear as length of fiducial
void resizeTuios(){
  ArrayList<TuioObject> tuioObjectList = tuioClient.getTuioObjectList();
  for (int i=0;i<tuioObjectList.size();i++) {
     TuioObject tobj = tuioObjectList.get(i);
     int tobj_id = tobj.getSymbolID();
     stroke(0);
     pushMatrix();
     translate(tobj.getScreenX(width),tobj.getScreenY(height));
     rotate(tobj.getAngle());
     int[] blockColor;
     blockColor = getBlockColor(tobj.getSymbolID());
     fill(blockColor[0], blockColor[1], blockColor[2]);
     rect(-obj_size/2,-obj_size/2,obj_size,tobj_id*obj_size);
     popMatrix();
     fill(0,0,0);
     text(""+tobj.getSymbolID(), tobj.getScreenX(width), tobj.getScreenY(height));
   }
}

// if button is clicked, catalog the pattern!
void catalogIfClicked(){
  ArrayList<TuioCursor> tuioCursorList = tuioClient.getTuioCursorList();
  for (int i=0;i<tuioCursorList.size();i++) {
    TuioPoint tcur = tuioCursorList.get(i).getPosition();
    float scaledX = tcur.getX() * width; 
    float scaledY = tcur.getY() * height;
    if (scaledX>10 && scaledX<155+10 && scaledY>10 && scaledY<10+40) {
      textSize(32);
      fill (255,3,3);
      text("Catalog it!",15,40);
      storePattern();
    }
  }
}

// returns (r,g,b) color array of the fiducial 
int[] getBlockColor(int fid_id){
  int[] reds = {0,50,100,0,200,0,100,50,190,100,0};
  int[] greens = {0,200,0,50,0,50,10,220,2,0,120};
  int[] blues = {0,190,200,150,250,50,0,150,140,150,180};
  int[] blockColor = {reds[fid_id], greens[fid_id], blues[fid_id]};
  return blockColor;
}

// checks all fiducials and stores contiguous pattern in pattern array 
void storePattern(){
  ArrayList<Block> curr_blocks = new ArrayList<Block>();
  ArrayList<TuioObject> tuioObjectList = tuioClient.getTuioObjectList();
  Collections.sort(tuioObjectList, y_coord_comparator);
  for (int i=0;i<tuioObjectList.size();i++) {
     TuioObject tobj = tuioObjectList.get(i);
     println("Y_coord of block " + i + " is: " + tobj.getPosition().getY());    
     Block tobj_block = new Block(tobj.getSymbolID());
     curr_blocks.add(tobj_block);
  }
  
  Pattern tobj_pattern = new Pattern(curr_blocks);
  my_patterns.add(tobj_pattern);
}

Comparator<TuioObject> y_coord_comparator = new Comparator<TuioObject>(){
  @Override
  int compare(TuioObject t1, TuioObject t2){
    return (int)Math.signum(t1.getPosition().getY() - t2.getPosition().getY());
  }
//  @Override
//  boolean equals(TuioObject t1, TuioObject t2){
//    return t1.getPosition().getY() == t2.getPosition().getY();
//  }
};


// --------------------------------------------------------------
////** Block Rectangle Class **////
// --------------------------------------------------------------
// A block is a 1:unit_height rectangle
class Block{
  int unit_height;
  // Custom Constructor
  Block(int id){
    unit_height = id;
  }
  // returns unit height of block
  int getHeight(){
    return unit_height;
  }
 
}


// --------------------------------------------------------------
////** Pattern Class **////
// --------------------------------------------------------------
// A block is a 1:unit_height rectangle
class Pattern{
  ArrayList<Block> my_blocks;
  // Custom Constructor
  Pattern(ArrayList<Block> blocks){
    my_blocks = blocks;
  }
  
  // returns blocks in this pattern
  ArrayList<Block> getBlocks(){
    return my_blocks;
  }
  
  // add block to bottom end of list (bottom of pattern)
  void addBlock(Block new_block){
    my_blocks.add(new_block);
  }
  
  // insert block to any point in list/pattern
  // @pre: 0 <= `idx` < my_blocks.size()
  void insertBlock(Block new_block, int idx){
    my_blocks.add(idx, new_block);
  }
  
  // draws the blocks pattern starting at (xpos,ypos) scaled by scale_factor
  void drawPattern(int xpos, int ypos, int scale_factor){
    int y_shift = 0;
    for (int i=0; i<my_blocks.size(); i++){
      int block_id = my_blocks.get(i).getHeight();
      int[] blockColor;
      blockColor = getBlockColor(block_id);
      fill(blockColor[0], blockColor[1], blockColor[2]);
      rect(xpos, ypos + y_shift, obj_size / scale_factor, block_id * obj_size / scale_factor);
      y_shift += block_id * obj_size / scale_factor;
    }
  }
  
}





// --------------------------------------------------------------
// --------------------------------------------------------------
// --------------------------------------------------------------
// Other stuff that may or may not be necessary
// --------------------------------------------------------------
// --------------------------------------------------------------
// --------------------------------------------------------------
// these callback methods are called whenever a TUIO event occurs
// there are three callbacks for add/set/del events for each object/cursor/blob type
// the final refresh callback marks the end of each TUIO frame

// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {
  if (verbose) println("add obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  if (verbose) println("set obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
          +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  if (verbose) println("del obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}

// --------------------------------------------------------------
// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  if (verbose) println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
  //redraw();
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  if (verbose) println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
  //redraw();
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  if (verbose) println("del cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
  //redraw()
}

// --------------------------------------------------------------
// called when a blob is added to the scene
void addTuioBlob(TuioBlob tblb) {
  if (verbose) println("add blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea());
  //redraw();
}

// called when a blob is moved
void updateTuioBlob (TuioBlob tblb) {
  if (verbose) println("set blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea()
          +" "+tblb.getMotionSpeed()+" "+tblb.getRotationSpeed()+" "+tblb.getMotionAccel()+" "+tblb.getRotationAccel());
  //redraw()
}

// called when a blob is removed from the scene
void removeTuioBlob(TuioBlob tblb) {
  if (verbose) println("del blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+")");
  //redraw()
}

// --------------------------------------------------------------
// called at the end of each TUIO frame
void refresh(TuioTime frameTime) {
  if (verbose) println("frame #"+frameTime.getFrameID()+" ("+frameTime.getTotalMilliseconds()+")");
  if (callback) redraw();
}
