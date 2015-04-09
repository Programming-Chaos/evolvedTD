// this is where sound goes

public class Sounds extends Thread {
  AudioPlayer a;
  
  public Sounds ( AudioPlayer ax ) {
    a = ax;
  }
  
  public void run () {
    a.rewind();
    a.play();
    delay(2000);
    a.close();
  }
}

void PlaySounds (String s) {
  AudioPlayer a;
  a = minim.loadFile(s);
  Sounds f = new Sounds(a);
  f.start(); 
}
