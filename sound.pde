// this is where sound goes

public class Sounds extends Thread {
  AudioPlayer a;
  
  public Sounds ( AudioPlayer ax ) {
    a = ax; 
  }
   public void run () {
     a.rewind();
     a.play();
   } 
}

void PlaySounds( AudioPlayer a ) {
   Sounds f = new Sounds(a);
   f.start(); 
}


