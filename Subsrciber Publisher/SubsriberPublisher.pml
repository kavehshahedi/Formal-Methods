#define subscribersCount  2

mtype:subscription = {SUBSCRIBED, UNSUBSCRIBED}
mtype:subscription subscribersStatus[subscribersCount];

mtype:subscriberRequest = {ENROLL, RELEASE}
chan request[subscribersCount] = [1] of {mtype:subscriberRequest};

mtype:publisherResponse = {ACCEPT, REJECT}
chan response[subscribersCount] = [1] of {mtype:publisherResponse};

chan publisherChannel[subscribersCount] = [0] of {int}

bit subscribersMessage[subscribersCount];
bit currentMessage;
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
                :: subscribersStatus[i] == SUBSCRIBED -> 
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
    subscribersStatus[id] = UNSUBSCRIBED;

    atomic{
        run enroll(id);
        run release(id);
    }

    bit message;
    do
    :: publisherChannel[id] ? message -> 
        subscribersMessage[id] = message
    od
}

proctype enroll(short id){
    mtype:publisherResponse result;

    do
    :: (subscribersStatus[id] == UNSUBSCRIBED) -> request[id] ! ENROLL -> 
        response[id] ? result -> 
        if
        :: result == ACCEPT -> 
            subscribersStatus[id] = SUBSCRIBED;
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
        :: subscribersStatus[id] == SUBSCRIBED -> request[id] ! RELEASE -> 
            response[id] ? result -> 
            if
            :: result == ACCEPT -> 
                subscribersStatus[id] = UNSUBSCRIBED;
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
                :: subscribersStatus[id] == UNSUBSCRIBED ->
                    response[id] ! ACCEPT;
                :: else -> response[id] ! REJECT;
                fi
            :: req == RELEASE ->
                if
                :: subscribersStatus[id] == SUBSCRIBED -> 
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
    [] ((canCheckLTL == true) -> (sentSubscribersCounter == lastSavedEnrolledSubscribers))
}

ltl liveness1{
    []((canCheckLTL == true) -> (subscribersMessage[0] == currentMessage))
}

ltl liveness2{
    []((canCheckLTL == true) -> (subscribersMessage[1] == currentMessage))
}