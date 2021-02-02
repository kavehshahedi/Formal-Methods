#define subscribersCount  2

mtype:subscription = {SUBSCRIBED, UNSUBSCRIBED}
mtype:subscription subscribersStatus[subscribersCount];

mtype:subscriberRequest = {ENROLL, RELEASE}
chan request[subscribersCount] = [1] of {mtype:subscriberRequest};

mtype:publisherResponse = {ACCEPT, REJECT}
chan response[subscribersCount] = [1] of {mtype:publisherResponse};

chan publisherChannel[subscribersCount] = [0] of {int}

bool canRelease = true;

int timeCounter;

proctype publisher(){
    bit message;
    do
    :: true ->
        if
        :: ((timeCounter >= 3) && (timeCounter % 2 == 1)) -> 
            int i = 0;
            do
            :: i < subscribersCount ->
                if
                :: subscribersStatus[i] == SUBSCRIBED -> 
                    publisherChannel[i] ! message;
                :: else -> skip;
                fi

                i++;
            :: i >= subscribersCount -> break;
            od

            message = 1 - message;
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

    int message;
    do
    :: publisherChannel[id] ? message -> 
        printf("Subscriber %d received message %d", id, message);
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
        :: else 
        fi
    od
}

proctype release(short id){
    mtype:publisherResponse result;

    if
    :: canRelease -> 
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
                :: subscribersStatus[id] == SUBSCRIBED -> response[id] ! ACCEPT;
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

proctype test(int id, in, out){
    printf("%d", id);
}

init{
    timeCounter = 0;

    atomic {
        run timer();
        run publisher();
        
        int i = 0;
        do
        :: i < subscribersCount ->
            run subscriptionManager();
            run subscriber(i);
            i++;
        :: i >= subscribersCount -> break;
        od
    }
}