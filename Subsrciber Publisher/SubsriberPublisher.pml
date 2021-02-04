#define subscribersCount  2

mtype:subscription = {SUBSCRIBED, UNSUBSCRIBED}

typedef subscribersStatusTypedef{
    mtype:subscription status;
    int time;
}
subscribersStatusTypedef subscribersStatus[subscribersCount];

mtype:subscriberRequest = {ENROLL, RELEASE}
chan request[subscribersCount] = [1] of {mtype:subscriberRequest};

mtype:publisherResponse = {ACCEPT, REJECT}
chan response[subscribersCount] = [1] of {mtype:publisherResponse};

chan publisherChannel[subscribersCount] = [0] of {int}

int subscribersMessage[subscribersCount];
int currentMessage;
bool canCheckLTL;

int sentSubscribersCounter;
int enrolledSubscribers;
int lastSavedEnrolledSubscribers;

bool canRelease = false;

int timeCounter;

proctype publisher(){
    int message = 10;
    do
    :: true ->
        if
        :: ((timeCounter >= 3) && (timeCounter % 2 == 1)) -> 
            canCheckLTL = false;
            sentSubscribersCounter = 0;
            lastSavedEnrolledSubscribers = enrolledSubscribers;

            int i = 0;
            do
            :: i < subscribersCount ->
                if
                :: (subscribersStatus[i].status == SUBSCRIBED) && (subscribersStatus[i].time < timeCounter) -> 
                    publisherChannel[i] ! message;
                    sentSubscribersCounter++;
                :: else -> skip;
                fi

                i++;
            :: i >= subscribersCount -> break;
            od

            currentMessage = message;
            canCheckLTL = true;
        :: else -> skip;
        fi
    od
}

proctype subscriber(short id){
    subscribersStatus[id].status = UNSUBSCRIBED;

    atomic{
        run enroll(id);
        run release(id);
    }

    int message;
    do
    :: publisherChannel[id] ? message -> 
        subscribersMessage[id] = message
    od
}

proctype enroll(short id){
    mtype:publisherResponse result;

    do
    :: (subscribersStatus[id].status == UNSUBSCRIBED) -> request[id] ! ENROLL -> 
        response[id] ? result -> 
        if
        :: result == ACCEPT -> 
            subscribersStatus[id].status = SUBSCRIBED;
            subscribersStatus[id].time = timeCounter;
            enrolledSubscribers++;
        :: else 
        fi
    od
}

proctype release(short id){
    mtype:publisherResponse result;

    if
    :: canRelease == true -> 
        do
        :: subscribersStatus[id].status == SUBSCRIBED -> request[id] ! RELEASE -> 
            response[id] ? result -> 
            if
            :: result == ACCEPT -> 
                subscribersStatus[id].status = UNSUBSCRIBED;
            :: else 
            fi
        od
    fi
}

proctype subscriptionManager(){
    mtype:subscriberRequest req;

    int id = 0;
    do
    :: id < subscribersCount -> 
        request[id] ? req -> 
            if
            :: req == ENROLL ->
                if
                :: subscribersStatus[id].status == UNSUBSCRIBED ->
                    response[id] ! ACCEPT;
                :: else -> response[id] ! REJECT;
                fi
            :: req == RELEASE ->
                if
                :: subscribersStatus[id].status == SUBSCRIBED -> 
                    response[id] ! ACCEPT;
                    enrolledSubscribers--;
                :: else -> response[id] ! REJECT;
                fi
            fi
        
        id++;
    :: id >= subscribersCount -> id = 0;
    od
}

proctype timer(){
    do
    :: timeCounter++;
    od
}

init{
    timeCounter = 0;
    enrolledSubscribers = 0;

    atomic {
        run timer();
        run publisher();
        run subscriptionManager();
        
        int i = 0;
        do
        :: i < subscribersCount ->
            run subscriber(i);
            i++;
        :: i >= subscribersCount -> break;
        od
    }
}

ltl safety {
    [] ((canCheckLTL == true) -> (sentSubscribersCounter == enrolledSubscribers))
}

ltl liveness1{
    []((canCheckLTL == true && subscribersStatus[0].status == SUBSCRIBED) -> (subscribersMessage[0] == currentMessage))
}

ltl liveness2{
    []((canCheckLTL == true && subscribersStatus[1].status == SUBSCRIBED) -> (subscribersMessage[1] == currentMessage))
}