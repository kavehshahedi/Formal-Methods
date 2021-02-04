mtype:signal = {RED, YELLOW, GREEN}
mtype:gate = {OPEN, LOWERED, CLOSED, RAISED}
mtype:train = {STOP, SLOW_DOWN, RESUME_NORMAL}

mtype:signal SignalStatus;
mtype:gate GateStatus;
mtype:train TrainStatus;

chan signalTrainChannel = [0] of {mtype:signal, mtype:train}
chan completeChannel = [0] of {mtype:gate, mtype:signal, mtype:train}

proctype handleRailRoadCrossing(){
    do
    :: GateStatus == OPEN -> 
        GateStatus = LOWERED; 
        atomic {
            signalTrainChannel ! YELLOW,SLOW_DOWN;
        }

    :: GateStatus == LOWERED -> 
        completeChannel ! CLOSED,GREEN,RESUME_NORMAL;
        
    :: GateStatus == CLOSED -> 
        GateStatus = RAISED; 
        atomic {
            signalTrainChannel ! YELLOW,SLOW_DOWN;
        }

    :: GateStatus == RAISED -> 
        completeChannel ! OPEN,RED,STOP;
    od;
}

proctype getSignalTrainStatus(){
    do
    :: atomic {
        signalTrainChannel ? SignalStatus,TrainStatus;
    }
    od
}

proctype getCompleteStatus(){
    do
    :: atomic {
        completeChannel ? GateStatus,SignalStatus,TrainStatus;
    }
    od
}

init {
    atomic {
        SignalStatus = RED;
        GateStatus = OPEN;
        TrainStatus = STOP;

        run handleRailRoadCrossing(); 
        run getSignalTrainStatus();
        run getCompleteStatus();
    }
}

ltl safety_open{
    [] ((GateStatus == OPEN) -> ((SignalStatus == RED) && (TrainStatus == STOP)))
}

ltl safety_closed{
    [] ((GateStatus == CLOSED) -> ((SignalStatus == GREEN) && (TrainStatus == RESUME_NORMAL)))
}

ltl safety_lowered{
    [] ((GateStatus == LOWERED) -> ((SignalStatus == YELLOW) && (TrainStatus == SLOW_DOWN)))
}

ltl safety_raised{
    [] ((GateStatus == RAISED) -> ((SignalStatus == YELLOW) && (TrainStatus == SLOW_DOWN)))
}