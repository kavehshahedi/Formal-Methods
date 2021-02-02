mtype:signal = {RED, YELLOW, GREEN}
mtype:gate = {OPEN, LOWERED, CLOSED, RAISED}
mtype:train = {STOP, SLOW_DOWN, RESUME_NORMAL}

mtype:signal SignalStatus;
mtype:gate GateStatus;
mtype:train TrainStatus;

chan gateChannel = [0] of {mtype:gate, mtype:signal, mtype:train}

proctype handleRailRoadCrossing(){
    do
    :: GateStatus == OPEN -> GateStatus = LOWERED;
    :: GateStatus == LOWERED -> gateChannel ! LOWERED,YELLOW,SLOW_DOWN; gateChannel ! CLOSED,GREEN,RESUME_NORMAL;
    :: GateStatus == CLOSED -> GateStatus = RAISED;
    :: GateStatus == RAISED -> gateChannel ! RAISED,YELLOW,SLOW_DOWN; gateChannel ! OPEN,RED,STOP;
    od; 
}

proctype getGateStatus(){
    do
    :: atomic {
        gateChannel ? GateStatus,SignalStatus,TrainStatus;
    }
    od;
}

init {
    SignalStatus = RED;
    GateStatus = OPEN;
    TrainStatus = STOP;
    
     run handleRailRoadCrossing(); 
     run getGateStatus();
}