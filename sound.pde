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

// Table of soundfiles and their lengths
Table soundfiles = new Table();

public class Sounds extends Thread {
  AudioPlayer a;
  int len;
  
  public Sounds ( AudioPlayer ax, int l ) {
    a = ax;
    len = l; //length of sound
  }
  
  public void run () {
    a.rewind();
    a.play();
    delay(len);
    a.close();
  }
}

void PlaySounds (String s) {
  AudioPlayer a;
  TableRow sound = soundfiles.findRow(s, "Key");
  
  if (sound != null) { //make sure that proper key was used
    String n = sound.getString("File");
    int l = sound.getInt("Length");
    
    a = minim.loadFile(n);
    Sounds f = new Sounds(a, l);
    f.start(); 
  }
  
  // print error if bad key was given
  else println('\"' + s + "\" is not a key in the sound table");
}


// Sets up the storage of our sound files and lengths
void setupSoundFiles() {
  soundfiles.addColumn("Key");
  soundfiles.addColumn("File");
  soundfiles.addColumn("Length");
  
  TableRow sf = soundfiles.addRow(); //Railgun_Long_01
  sf.setString("Key", "Railgun_Long_01");
  sf.setString("File", "assets/Turret-Railgun/railgunfire01long.mp3");
  sf.setInt("Length", 3000);
  
  sf = soundfiles.addRow(); //Railgun_Slow_01
  sf.setString("Key", "Railgun_Slow_01");
  sf.setString("File", "assets/Turret-Railgun/railgunfire01slow_01.mp3");
  sf.setInt("Length", 1000);
  
  sf = soundfiles.addRow(); //Ricochet_01
  sf.setString("Key", "Ricochet_01");
  sf.setString("File", "assets/Turret-Plasma/ricochet1.mp3");
  sf.setInt("Length", 2000);
  
  sf = soundfiles.addRow(); //Ricochet_02
  sf.setString("Key", "Ricochet_02");
  sf.setString("File", "assets/Turret-Plasma/ricochet2.mp3");
  sf.setInt("Length", 2000);
  
  sf = soundfiles.addRow(); //Laser_01
  sf.setString("Key", "Laser_01");
  sf.setString("File", "assets/Turret-Laser/laser.mp3");
  sf.setInt("Length", 2000);
  
  sf = soundfiles.addRow(); //Cannon_01
  sf.setString("Key", "Cannon_01");
  sf.setString("File", "assets/Turret-Freeze/Cannon.mp3");
  sf.setInt("Length", 3000);
  
  sf = soundfiles.addRow(); //Thunder_01
  sf.setString("Key", "Thunder_01");
  sf.setString("File", "assets/Thunder.mp3");
  sf.setInt("Length", 6000);
  
  sf = soundfiles.addRow(); //Upgrade_01
  sf.setString("Key", "Upgrade_01");
  sf.setString("File", "assets/upgrade.mp3");
  sf.setInt("Length", 1000);
  
  sf = soundfiles.addRow(); //Munch_01
  sf.setString("Key", "Munch_01");
  sf.setString("File", "assets/munch1.mp3");
  sf.setInt("Length", 1000);
  
  sf = soundfiles.addRow(); //Munch_02
  sf.setString("Key", "Munch_02");
  sf.setString("File", "assets/munch2.mp3");
  sf.setInt("Length", 1000);
  
  sf = soundfiles.addRow(); //Munch_03
  sf.setString("Key", "Munch_03");
  sf.setString("File", "assets/munch3.mp3");
  sf.setInt("Length", 1000);
  
  TestSoundFiles();
}

// Tests if the soundfiles actually exist
void TestSoundFiles() {
  AudioPlayer a;
  String path;
  Boolean pass = true;
  
  for (TableRow row : soundfiles.rows()) {
    path = row.getString("File");
    File file = new File(sketchPath(path));
    
    if (!file.exists()) {
      println("Failed to load sound " + path);
      pass = false;
    }
  } 
  
  if (pass) {
    println("All sound files found");
    println("Passed Sound Check :)");
  }
  else {
    println("Failed to load some sound files");
    println("Failed Sound Check :(");
  }
}
