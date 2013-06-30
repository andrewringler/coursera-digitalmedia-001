Maxim maxim;
Sound[] sounds;
int w = 400;
int h = 400;
int soundH, marginY, totalMargins;
int play1 = 0;
int play2 = 1;
float threshold = 0.2;
boolean beat = false;
int hold = 0;
float time = 1.5;
int[] primes = new int[] {
  /*  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, */
  31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 
  127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 
  179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 
  233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 
  283, 293, 307, 311, 313, 317, 331, 337, 347, 349
};
// a little more interesting when they are prime I think
// should also help prevent spirals I think
int numSquares = primes[round(random(0, primes.length-1))];
float rotationDirection = 1.0; // clockwise
int transitionFrames = 3;
int songSquareSize = 20;

void setup() {
  println("Loading...");
  frameRate(25);
  ellipseMode(CORNER);
  rectMode(CORNER);
  size(w, h);
  maxim = new Maxim(this);
  sounds = new Sound[] {
    new Sound("looperman-l-0348349-0064279-harveybluntman-unique-dub-synth.wav"), 
    new Sound("looperman-l-0373461-0040024-jogurtti-fun-hoover-2.wav"), 
    new Sound("looperman-l-0478115-0052314-kingballatore-house-loop-001.wav"), 
    new Sound("looperman-l-0510880-0057452-spadeofficial-house-groove-loop-organ-sidechained.wav"), 
    new Sound("looperman-l-0608380-0052023-pixieboots-angry-kick-beat.wav"), 
    new Sound("looperman-l-0767388-0056877-krextor-drillers-wobbles.wav"), 
    new Sound("looperman-l-0907685-0063065-blueeskies-synth-bleep.wav")
    };
    background(0);

  for (int i=0; i<sounds.length; i++) {
    Sound sound = sounds[i];
    if (i == play1 || i == play2) {
      sound.play();
    }
    else {
      sound.stop();
    }
  }
  println("Done.");
}

void draw()
{
  // fade more quickly after a beat to clear it
  float fadeAlpha = 10 + 200*hold/transitionFrames;
  background(0, 0, 0, fadeAlpha);

  // draw a square for each song, highlight those that are playing
  float mid = (width-20.0)/(float)sounds.length - songSquareSize*2.0;
  for (int i=0; i<sounds.length; i++) {
    float x = mid + lerp(0, width-20, (float)i/sounds.length) + 10;
    float y = height-songSquareSize-10;
    if (sounds[i].player.isPlaying()) {
      // draw square to signify playing
      fill(200, 200, 0);
      rect(x, y, songSquareSize, songSquareSize);
      sounds[i].updatePower();
    }
    else {
      noStroke();
      fill(80);
      rect(x, y, songSquareSize, songSquareSize);
    }
  }

  pushMatrix();
  // Beat Detection
  if (hold > 0) {
    // keep animating current beat
    beat = true;
  }
  else {
    // detect new beat
    if (sounds[play1].power.beatDetect() || sounds[play2].power.beatDetect()) {
      // simple beat detection
      beat = true;
      hold = transitionFrames; // hold beat for duration of animation
    }
    else {
      beat = false;
    }
  }

  // Visualation
  translate(mouseX, mouseY);
  if (mouseX > pmouseX) {
    // dragging to the right, lets rotate clockwise
    rotationDirection = 1;
  }
  else {
    rotationDirection = -1;
  }

  for (int j=0; j<numSquares; j++) {
    stroke(200, 200, 0, 50);
    if (beat) {
      int alpha = (int)(50.0*hold/transitionFrames);
      fill(160, 90, 0, alpha);
    }
    else {
      noFill();
    }
    // j*0.03 should prevent spirals I think
    rotate(rotationDirection * (time + j*0.03));

    float size = j*5;
    if (beat) {
      //    scale(1.0 + hold/transitionFrames*1.1); // cycle from 1.4 back to 1
      size *= 1.0 + hold/transitionFrames*1.1; // cycle from 1.4 back to 1
    }

    rect(j, j, size, size);

    // some extra fill near the mouse
    noStroke();
    fill(100 + j/numSquares * 50, 100 + j/numSquares*10, 0, 5);
    ellipse(j, j, size, size);
  }
  popMatrix();

  hold--;
  time += 0.01;
}

void mouseMoved() {
  /* we only every play 2 songs simultaneously
   * with low probability swap out one song for another
   */
  if (random(0, 1) > 0.99) {
    int swapOut = round(random(0, 1));
    int numSquares = primes[round(random(0, primes.length-1))];
    time = 1.5;

    if (swapOut == 0) {
      play1 = round(random(0, sounds.length-1));
    }
    else {
      // there is a chance play1 == play2, thats OK
      // it just means we only have 1 song playing
      play2 = round(random(0, sounds.length-1));
    }

    for (int i=0; i<sounds.length; i++) {
      Sound sound = sounds[i];
      if (i == play1 || i == play2) {
        sound.play();
      }
      else {
        sound.stop();
      }
    }
  }
}

void mouseClicked() {
}

void mouseDragged()
{
}

void mouseReleased()
{
}

class Sound {
  String path;
  AudioPlayer player;
  Power power = new Power();

  public Sound(String path) {
    this.path = path;
    player = maxim.loadFile(path);
    player.setLooping(true);
    player.setAnalysing(true);
  }

  void updatePower() {
    power.add(player.getAveragePower());
  }

  void play() {
    player.play();
  }

  void stop() {
    player.stop();
    power.reset();
  }
}

class Power {
  int samples = 0;
  float powerTotal = 0;
  float cur = 0;

  void add(float power) {
    cur = power;
    powerTotal += power;
    samples++;
  }

  boolean beatDetect() {
    // detect new beat (must be 20% greater than average power)
    return ready() && cur > (avgPower()*1.20);
  }

  boolean ready() {
    return samples > 25;
  }

  float avgPower() {
    if (samples > 0) {
      return powerTotal / samples;
    }
    return 0;
  }

  void reset() {
    samples = 0;
    powerTotal = 0;
  }
}

