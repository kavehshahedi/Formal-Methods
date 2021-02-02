byte trafficLightTurn = 0;

mtype trafficLightOneColor;
mtype trafficLightTwoColor;

mtype = {
    Green, 
    Yellow, 
    Red
};

proctype TrafficLightOne() {
    trafficLightOneColor = Red;

    do 
    :: (trafficLightTurn == 0 && trafficLightOneColor == Red) -> trafficLightOneColor = Yellow;
    :: (trafficLightTurn == 0 && trafficLightOneColor == Yellow) -> trafficLightOneColor = Green;
    :: (trafficLightTurn == 0 && trafficLightOneColor == Green) -> trafficLightOneColor = Red; trafficLightTurn = 1;
    od
}

proctype TrafficLightTwo() {
    trafficLightTwoColor = Red;
    
    do 
    :: (trafficLightTurn == 1 && trafficLightTwoColor == Red) -> trafficLightTwoColor = Yellow;
    :: (trafficLightTurn == 1 && trafficLightTwoColor == Yellow) -> trafficLightTwoColor = Green; 
    :: (trafficLightTurn == 1 && trafficLightTwoColor == Green) -> trafficLightTwoColor = Red; trafficLightTurn = 0;
    od
}

init {
    atomic {
        run TrafficLightOne();
        run TrafficLightTwo();
    }
}