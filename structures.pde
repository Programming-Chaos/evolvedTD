class structure {
  int ID;
  char type;
  tower t;
  farm f;
  cable c;
  int moneyinvested;
  
  structure(char tp, int id) {
    moneyinvested = 0;
    ID = id;
    switch (tp) {
      case 'b':
      case 'd':
        type = 'f';
        f = new farm(tp, ID, this);
        break;
      case 'r':
      case 'p':
      case 'i':
      case 'l':
      case 'g':
        type = 't';
        t = new tower(tp, ID, this);
        break;
      case 'c':
        type = 'c';
        c = new cable(tp,ID, this);
    }
  }
}

class pulse {
  ArrayList<structure> poweredStructures;
  IntList visitedStructureIDs;
  farm bioreactor;
  int e;
  
  pulse(farm b, int en) {
    poweredStructures = new ArrayList<structure>();
    visitedStructureIDs = new IntList();
    bioreactor = b;
    e = en;
    transmit(b.parent);
    addEnergy();
  }
  
  void transmit(structure z) {
    if (z.type == 'c') {
      if (visitedStructureIDs.hasValue(z.c.cableID)) return; // this structure has been visited before and shouldn't be visited again
    }
    else if (visitedStructureIDs.hasValue(z.ID)) return; // this structure has been visited before and shouldn't be visited again
    if (z.type == 'c') visitedStructureIDs.append(z.c.cableID);
    else visitedStructureIDs.append(z.ID);
    switch (z.type) {
      case 't':
        poweredStructures.add(z);
        break;
      case 'f':
        switch (z.f.type) {
          case 'd':
            poweredStructures.add(z);
            break;
          case 'b':
            for (cable c : z.f.connectedCables)
              transmit(c.parent);
            break;
        }
        break;
      case 'c':
        for (structure s : z.c.connectedStructures)
          transmit(s);
        transmit(z.c.otherEnd.parent);
        break;
    }
  }
  
  void addEnergy() { // conservation of energy is important
    if (poweredStructures.size() == 0) return;
    int portion = e/poweredStructures.size();
    int remainder = (e-(portion*poweredStructures.size()));
    for (structure s : poweredStructures) { // first all towers get their fair slice of the energy allottment
      if (s.type == 't') {
        if ((s.t.maxEnergy-s.t.energy) < portion) {
          remainder += (portion-(s.t.maxEnergy-s.t.energy));
          s.t.energy = s.t.maxEnergy;
        }
        else s.t.energy += portion;
      }
      else {
        if ((s.f.maxEnergy-s.f.energy) < portion) {
          remainder += (portion-(s.f.maxEnergy-s.f.energy));
          s.t.energy = s.t.maxEnergy;
        }
        else s.f.energy += portion;
      }
    }
    if (remainder > 0) { // then the remainder is used to top off towers in a random order of priority
      IntList order = new IntList();
      for (int i = 0; i < poweredStructures.size(); i++)
        order.append(i);
      order.shuffle();
      for (int i = 0; i < poweredStructures.size(); i++) {
        if (remainder == 0) break;
        if (poweredStructures.get(order.get(i)).type == 't') {
          if ((poweredStructures.get(order.get(i)).t.maxEnergy-poweredStructures.get(order.get(i)).t.energy) < remainder) {
            remainder -= (portion-(poweredStructures.get(order.get(i)).t.maxEnergy-poweredStructures.get(order.get(i)).t.energy));
            poweredStructures.get(order.get(i)).t.energy = poweredStructures.get(order.get(i)).t.maxEnergy;
          }
          else {
            poweredStructures.get(order.get(i)).t.energy += remainder;
            remainder = 0;
          }
        }
        else {
          if ((poweredStructures.get(order.get(i)).f.maxEnergy-poweredStructures.get(order.get(i)).f.energy) < remainder) {
            remainder -= (portion-(poweredStructures.get(order.get(i)).f.maxEnergy-poweredStructures.get(order.get(i)).f.energy));
            poweredStructures.get(order.get(i)).f.energy = poweredStructures.get(order.get(i)).f.maxEnergy;
          }
          else {
            poweredStructures.get(order.get(i)).f.energy += remainder;
            remainder = 0;
          }
        }
      }
    }
  }
}
