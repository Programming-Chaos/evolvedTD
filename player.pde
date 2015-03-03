class player {
  int resources;
  ArrayList<tower> towers;
  
  player(){
    towers = new ArrayList<tower>();
  }
  
  void display(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.display();  // display them all
    }
    // player UI here
  }
  
  void addtower(tower t){
    towers.add(t);
  }
  
  void update(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.update();   // update them
    }
  }
  
}
