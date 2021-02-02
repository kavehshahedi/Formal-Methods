mtype trafficLightOneColor;
mtype trafficLightTwoColor;

mtype currentColor;

mtype = {
    Green, 
    Yellow, 
    Red
};

proctype TrafficLights() {
    currentColor = Red;
    
    do 
    :: (currentColor == Red) -> atomic { currentColor = Yellow; trafficLightOneColor = Yellow; trafficLightTwoColor = Yellow; }
    :: (currentColor == Yellow) -> atomic { currentColor = Green; trafficLightOneColor = Green; trafficLightTwoColor = Green; }
    :: (currentColor == Green) -> atomic { currentColor = Red; trafficLightOneColor = Red; trafficLightTwoColor = Red; }
    od
}

init {
    run TrafficLights();
}