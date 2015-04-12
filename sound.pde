// this is where sound goes

// object for storing soundfile name and length
class SoundFile {
  String name;
  int len;
 
  SoundFile(String n, int l) {
    name = n;
    len = l;
  } 
}

// list of soundfiles and their lengths
ArrayList<SoundFile> soundfiles = new ArrayList<SoundFile>();

void setupSoundFiles() {
  soundfiles.add(new SoundFile("assets/railgunfire01long.mp3", 3000));     //0
  soundfiles.add(new SoundFile("assets/railgunfire01slow_01.mp3", 1000));  //1
  soundfiles.add(new SoundFile("assets/ricochet1.mp3", 2000));             //2
  soundfiles.add(new SoundFile("assets/Cannon.mp3", 3000));                //3
  soundfiles.add(new SoundFile("assets/Thunder.mp3", 6000));               //4
}

public class Sounds extends Thread {
  AudioPlayer a;
  int len;
  
  public Sounds ( AudioPlayer ax, int l ) {
    a = ax;
    len = l;
  }
  
  public void run () {
    a.rewind();
    a.play();
    delay(len);
    a.close();
  }
}

void PlaySounds (int s) {
  AudioPlayer a;
  String n = soundfiles.get(s).name;
  int l = soundfiles.get(s).len;
  a = minim.loadFile(n);
  Sounds f = new Sounds(a, l);
  f.start(); 
}
