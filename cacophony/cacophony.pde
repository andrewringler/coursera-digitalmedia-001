Maxim maxim;
AudioPlayer[] players;
int nSoundsVisible = 9;
int nSounds = 10; // must be > nSoundsVisible
int primarySound = 4; //0-indexed
int selectedSound = 4;
int maxAttenuationDist = 2; //only hear sound X indexes away from center
int h = 40;

void setup()
{
  size(800, 500);
  background(0);

  maxim = new Maxim(this);
  players = new AudioPlayer[nSounds];
  println("Loading songs...");
  String base = "wfmu/";
  for (int i=0; i<nSounds; i++) {
    players[i] = maxim.loadFile(base + (i+1) + ".wav");
    players[i].setAnalysing(true);
  }
}

void stop() {
  maxim.stop();
}

void draw()
{
  background(0);
  int w = (int) width / nSoundsVisible;
  w = (w / 2) * 2; // make even
  int maxWidth = w * nSoundsVisible;
  int middle = maxWidth / 2;

  // Attenuation (factor of 0-3), click to change
  rectMode(CENTER);
  fill(50);
  rect(middle, height/2 - 20, maxWidth, 5); 
  fill(255);
  rect(middle, height/2 - 20, w + 2*maxAttenuationDist*w, 5);
  fill(200);
  textAlign(LEFT, TOP);
  textSize(16);
  text("attenuation", 10, height/2 - 20 - 16 - 10); 

  // Handle all visible sounds
  int visibleIndex = 0;
  /* a window of visible sounds
   * over the list of all possible
   * sounds
   */
  int i = selectedSound - primarySound;
  i = i < 0 ? nSounds+i : i;
  while (visibleIndex < nSounds) {
    if (visibleIndex < nSoundsVisible) {
      int x = visibleIndex * w;
      float vol = 0;
      int dist = abs(primarySound - visibleIndex);
      if (dist <= maxAttenuationDist) {
        // half volume every step away from center
        vol = constrain(1 / pow(2, dist), 0, 1);
      }
      float pow = constrain(players[i].getAveragePower(), 0, 1);

      pushMatrix();    
      translate(x, height/2);

      // Animated power-level bar-chart
      fill(50);
      rectMode(CORNER);
      rect(0, 0, w, h);
      fill(255, 0, 0, map(vol, 0, 1, 0, 255));
      rectMode(BOTTOM);
      rect(0, h, w, h- (pow*h));

      // Show some real-time stats/info
      int txtMargin = 5;
      fill(200);
      textAlign(LEFT, TOP);
      textSize(32);
      text(i, 0, h + txtMargin); 
      textSize(11);
      text("pow: "+nf(pow, 1, 2), 0, h + txtMargin+32+11*1); 
      text("vol: "+nf(vol, 1, 2), 0, h + txtMargin+32+11*0); 

      players[i].volume(vol);
      players[i].play();

      if (visibleIndex < primarySound) {
        players[i].pan(-1); // pan left
      } 
      else if (visibleIndex > primarySound) {
        players[i].pan(1); // pan right
      } 
      else {
        players[i].pan(0); // both channels equal
      }

      popMatrix();
    } 
    else {      
      players[i].stop(); // sound is not visible
    }

    visibleIndex++;
    i++;
    i = i >= nSounds ? 0 : i;
  }
}

void mousePressed() {
}

void mouseClicked() {
  // Adjust Attenuation
  int w = (int) width / nSoundsVisible;
  int maxWidth = w * nSoundsVisible;
  int middle = maxWidth / 2;
  int aHeight = 20;
  int top = height/2 - 20 - aHeight/2;
  int bottom = height/2 - 20 + aHeight/2;

  if (mouseY > top && mouseY < bottom) {
    int distToMiddle = abs(middle - mouseX);
    maxAttenuationDist = (distToMiddle+w/2) / w;
  }

  // Change primary sound sample, move to center
  int sampleTop = height/2;
  int sampleBottom = sampleTop + h;
  if (mouseY > sampleTop && mouseY < sampleBottom) {
    int distToMiddle = abs(middle - mouseX);
    int delta = (distToMiddle+w/2) / w;
    delta = (middle-mouseX)>0 ? -delta : delta;
    int newSound = selectedSound + delta;
    newSound = newSound >= nSounds ? nSounds-newSound /* wrap-around from back */ : newSound;
    newSound = newSound < 0 ? nSounds+newSound /* wrap-around to begining */ : newSound;
    selectedSound = constrain(newSound, 0, nSounds);
  }
}

